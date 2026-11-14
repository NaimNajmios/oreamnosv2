import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/constants.dart';
import 'config/routes/app_router.dart';
import 'config/theme/app_theme.dart';
import 'core/di/injection.dart';
import 'domain/models/app_theme_mode.dart';
import 'domain/models/card_brief.dart';
import 'domain/models/curated_post.dart';
import 'domain/models/home_widget_snapshot.dart';
import 'domain/services/home_widget_snapshot_builder.dart';

import 'ui/features/settings/view_models/settings_view_model.dart';
import 'ui/features/generate/view_models/generate_view_model.dart';
import 'ui/features/facebook/view_models/facebook_view_model.dart';
import 'data/services/facebook_history_service.dart';
import 'data/services/facebook_reminder_service.dart';
import 'data/services/daily_usage_service.dart';
import 'data/services/home_widget_service.dart';
import 'data/services/share_intent_service.dart';
import 'data/services/notification_service.dart';
import 'data/services/usage_service.dart';
import 'ui/features/publish/view_models/facebook_drafts_view_model.dart';

/// Root application widget.
class OreamnosApp extends ConsumerStatefulWidget {
  const OreamnosApp({super.key});

  @override
  ConsumerState<OreamnosApp> createState() => _OreamnosAppState();
}

class _OreamnosAppState extends ConsumerState<OreamnosApp> {
  late final GoRouter _router;
  late final AppLifecycleListener _lifecycleListener;
  late final HomeWidgetService _homeWidget;
  StreamSubscription<Uri?>? _widgetClicks;
  Timer? _widgetSyncDebounce;
  bool _widgetSyncInFlight = false;
  final Map<String, HomeWidgetPalette> _widgetPalettes = {};

  /// Content of the share currently being processed — guards against a
  /// slow double-delivery (stream bounce after the service dedup window)
  /// starting two generations of the same input. Shares with *different*
  /// content always supersede (session-id cancel model handles the rest).
  String? _inFlightShareContent;

  @override
  void initState() {
    super.initState();
    _router = createAppRouter();
    _homeWidget = getIt<HomeWidgetService>();
    _listenForWidgetClicks();
    _lifecycleListener = AppLifecycleListener(
      onResume: () {
        // Cheap presence probe: a stale token or lost connection should be
        // visible before the user spends a minute composing a post.
        try {
          ref.read(facebookViewModelProvider.notifier).checkConnectionHealth();
          // A failed scheduled-post sync may have exhausted its 2s/8s/30s
          // backoff while the app was backgrounded. Retry on resume once the
          // 15-minute floor passes.
          if (ref.read(facebookViewModelProvider).isConnected) {
            unawaited(
              ref.read(facebookDraftProvider.notifier).reconcileIfStale(),
            );
          }
        } catch (_) {}
        _syncReminders();
        // The widget shows "updated 2d ago" when stale; a resume is the first
        // moment we can refresh it. Also catches a theme changed on another
        // surface and the midnight Pacific quota reset.
        _syncHomeWidget();
      },
    );

    // One reminder per scheduled post, refreshed whenever history changes.
    // The same listener keeps the home-screen widget's next-up in step.
    ref.listenManual(facebookHistoryProvider, (_, _) {
      _syncReminders();
      _scheduleHomeWidgetSync();
    });

    // Quota, drafts and connection state all feed the widget payload.
    ref.listenManual(
      facebookDraftsProvider,
      (_, _) => _scheduleHomeWidgetSync(),
    );
    ref.listenManual(
      usageNotifierProvider,
      (_, _) => _scheduleHomeWidgetSync(),
    );
    ref.listenManual(facebookViewModelProvider, (previous, next) {
      if (previous?.connectionRevision != next.connectionRevision ||
          previous?.status != next.status) {
        _scheduleHomeWidgetSync();
      }
    });
    ref.listenManual(settingsViewModelProvider, (previous, next) {
      if (previous?.themeMode != next.themeMode ||
          previous?.selectedModel != next.selectedModel ||
          previous?.selectedProvider != next.selectedProvider) {
        _scheduleHomeWidgetSync();
      }
    });

    // Request notification permissions after app launch
    Future.microtask(() {
      try {
        NotificationService().requestPermission();
      } catch (_) {}
      _syncReminders();
      _syncHomeWidget();
    });

    // Route notification actions (tone quick chooser, open, copy) — must be set after DI.
    NotificationService().onAction = (payload, actionId) async {
      if (payload == 'facebook_scheduled_post') {
        if (mounted) {
          _router.go('${RoutePaths.facebookHistory}?tab=scheduled');
        }
        return;
      }
      if (actionId == null || actionId == 'open_app') {
        if (payload != null && payload.isNotEmpty) {
          try {
            final jsonMap = jsonDecode(payload) as Map<String, dynamic>;
            final curated = CuratedPost.fromJson(jsonMap);
            if (mounted) {
              _router.go(RoutePaths.readingMode, extra: curated);
              return;
            }
          } catch (_) {}
        }

        final prefs = await SharedPreferences.getInstance();
        final jsonStr = prefs.getString('bg_last_generated_json');
        if (jsonStr != null && jsonStr.isNotEmpty) {
          try {
            final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
            final curated = CuratedPost.fromJson(jsonMap);
            if (mounted) {
              _router.go(RoutePaths.readingMode, extra: curated);
              return;
            }
          } catch (_) {}
        }

        final markdown = prefs.getString('bg_last_generated_markdown');
        if (markdown != null && markdown.isNotEmpty && mounted) {
          _router.go(RoutePaths.readingMode, extra: markdown);
          return;
        }

        if (mounted) {
          _router.go(RoutePaths.generate);
        }
        return;
      }
    };

    ShareIntentService().onSharedTextReceived = (text) {
      if (!mounted) return;
      final trimmed = text.trim();
      if (_inFlightShareContent == trimmed) {
        // Identical share already being processed (double delivery).
        return;
      }
      _inFlightShareContent = trimmed;
      // Late stream bounces (beyond the service's 1500ms dedup window) must
      // not re-trigger generation of the same share. But the guard must not
      // pin "in flight" for the whole multi-minute retry/fallback chain
      // either, or a deliberate re-share minutes later gets dropped — so
      // the pin expires after 8s (the bounce window) as a hard cap.
      Timer(const Duration(seconds: 8), () {
        if (_inFlightShareContent == trimmed) _inFlightShareContent = null;
      });

      // Defer to the first frame so the router/shell exists before the
      // share-driven navigation and generation kick off (cold-start race).
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          if (!mounted) return;

          // Dismiss any open modal dialogs on root navigator
          try {
            rootNavigatorKey.currentState?.popUntil((route) => route.isFirst);
          } catch (_) {}

          // Route-to-card alias (Android `ShareRouterActivity` parity): shared
          // text starting with `card:` opens Card Studio directly with the
          // remainder as the headline. Everything else auto-generates.
          final lower = trimmed.toLowerCase();
          if (lower.startsWith('card:') || lower.startsWith('kad:')) {
            final headline = trimmed.substring(trimmed.indexOf(':') + 1).trim();
            if (headline.isNotEmpty) {
              final settings = ref.read(settingsViewModelProvider);
              final modelId = (settings.selectedModel?.isNotEmpty ?? false)
                  ? settings.selectedModel!
                  : settings.selectedProvider.defaultModelId;
              _router.go(
                RoutePaths.cardGenerator,
                extra: CardBrief(
                  headline: headline,
                  subtext: '',
                  provider: settings.selectedProvider,
                  modelId: modelId,
                ),
              );
              return;
            }
          }

          _router.go(RoutePaths.generate);
          final notifier = ref.read(generateViewModelProvider.notifier);
          await notifier.handleExternalSharedInput(text);
        } finally {
          if (_inFlightShareContent == trimmed) {
            _inFlightShareContent = null;
          }
        }
      });
    };
    ShareIntentService().initialize();
  }

  void _syncReminders() {
    try {
      final service = getIt<FacebookReminderService>();
      final records = ref.read(facebookHistoryProvider);
      unawaited(service.sync(records));
    } catch (_) {}
  }

  /// Cold-start taps arrive as the launch intent, warm taps on the stream.
  /// Both carry a `oreamnos://` URI that maps onto an existing route.
  void _listenForWidgetClicks() {
    if (!_homeWidget.isSupported) return;
    try {
      _widgetClicks = _homeWidget.clicks.listen(_openWidgetUri);
    } catch (_) {}
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final uri = await _homeWidget.initialLaunchUri();
      _openWidgetUri(uri);
    });
  }

  void _openWidgetUri(Uri? uri) {
    if (!mounted) return;
    final location = RoutePaths.forWidgetUri(uri);
    if (location == null) return;
    _router.go(location);
  }

  /// Coalesces a burst of provider updates (a reconcile writes history several
  /// times) into one widget write.
  void _scheduleHomeWidgetSync() {
    if (!_homeWidget.isSupported) return;
    _widgetSyncDebounce?.cancel();
    _widgetSyncDebounce = Timer(
      const Duration(milliseconds: 400),
      () => unawaited(_syncHomeWidget()),
    );
  }

  Future<void> _syncHomeWidget() async {
    if (!_homeWidget.isSupported || !mounted || _widgetSyncInFlight) return;
    _widgetSyncInFlight = true;
    try {
      final settings = ref.read(settingsViewModelProvider);
      final connection = ref.read(facebookViewModelProvider);
      final records = ref.read(facebookHistoryProvider);
      final drafts = ref.read(facebookDraftsProvider);
      final now = DateTime.now();

      DailyUsageService? daily;
      if (getIt.isRegistered<DailyUsageService>()) {
        daily = getIt<DailyUsageService>();
      }
      final quotas = daily == null
          ? const <HomeWidgetQuota>[]
          : [
              for (final quota in daily.todayGeminiQuota())
                HomeWidgetQuota(
                  modelId: quota.modelId,
                  requestsToday: quota.requestsToday,
                  budget: quota.budget,
                ),
            ];

      final snapshot = const HomeWidgetSnapshotBuilder().build(
        now: now,
        records: records,
        quotas: quotas,
        pageName: connection.pageName,
        pageConnected: connection.isConnected,
        pageExpired: connection.isExpired,
        draftCount: drafts.length,
        palette: _paletteFor(settings.themeMode),
        selectedProviderId: settings.selectedProvider.name,
        selectedModel: settings.selectedModel,
        quotaResetAt: daily == null || quotas.isEmpty
            ? null
            : now.add(daily.timeUntilPacificReset()),
      );
      await _homeWidget.push(snapshot);
    } catch (_) {
      // A widget write must never surface to the user.
    } finally {
      _widgetSyncInFlight = false;
    }
  }

  /// Palm-sized mirror of the app palette. Dynamic colour is intentionally
  /// skipped: the widget has to render the same way for a background update
  /// that has no `DynamicColorBuilder` context, and the nine curated palettes
  /// are the app's actual identity.
  HomeWidgetPalette _paletteFor(AppThemeMode mode) {
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final key = '${mode.name}:${brightness.name}';
    final cached = _widgetPalettes[key];
    if (cached != null) return cached;

    final theme = switch (mode) {
      AppThemeMode.light => AppTheme.light(),
      AppThemeMode.dark => AppTheme.dark(),
      AppThemeMode.deepBlue => AppTheme.deepBlue(),
      AppThemeMode.midnightNoir => AppTheme.midnightNoir(),
      AppThemeMode.solarizedLight => AppTheme.solarizedLight(),
      AppThemeMode.cyberpunk => AppTheme.cyberpunk(),
      AppThemeMode.matchday => AppTheme.matchday(),
      AppThemeMode.forest => AppTheme.forest(),
      AppThemeMode.system =>
        brightness == Brightness.dark ? AppTheme.dark() : AppTheme.light(),
    };
    final scheme = theme.colorScheme;
    final palette = HomeWidgetPalette(
      surface: scheme.surface.toARGB32(),
      onSurface: scheme.onSurface.toARGB32(),
      muted: scheme.onSurfaceVariant.toARGB32(),
      primary: scheme.primary.toARGB32(),
    );
    _widgetPalettes[key] = palette;
    return palette;
  }

  @override
  void dispose() {
    _widgetSyncDebounce?.cancel();
    _widgetClicks?.cancel();
    _lifecycleListener.dispose();
    ShareIntentService().dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsViewModel = ref.watch(settingsViewModelProvider);
    final themeMode = settingsViewModel.isInitialized
        ? settingsViewModel.themeMode
        : AppThemeMode.system;

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final ThemeData themeData;
        final ThemeData? darkThemeData;
        final ThemeMode materialThemeMode;

        switch (themeMode) {
          case AppThemeMode.light:
            themeData = AppTheme.light(dynamicColorScheme: lightDynamic);
            darkThemeData = null;
            materialThemeMode = ThemeMode.light;
          case AppThemeMode.dark:
            themeData = AppTheme.dark(dynamicColorScheme: darkDynamic);
            darkThemeData = null;
            materialThemeMode = ThemeMode.dark;
          case AppThemeMode.deepBlue:
            themeData = AppTheme.deepBlue();
            darkThemeData = null;
            materialThemeMode = ThemeMode.dark;
          case AppThemeMode.midnightNoir:
            themeData = AppTheme.midnightNoir();
            darkThemeData = null;
            materialThemeMode = ThemeMode.dark;
          case AppThemeMode.solarizedLight:
            themeData = AppTheme.solarizedLight(
              dynamicColorScheme: lightDynamic,
            );
            darkThemeData = null;
            materialThemeMode = ThemeMode.light;
          case AppThemeMode.cyberpunk:
            themeData = AppTheme.cyberpunk();
            darkThemeData = null;
            materialThemeMode = ThemeMode.dark;
          case AppThemeMode.matchday:
            themeData = AppTheme.matchday(dynamicColorScheme: lightDynamic);
            darkThemeData = null;
            materialThemeMode = ThemeMode.light;
          case AppThemeMode.forest:
            themeData = AppTheme.forest();
            darkThemeData = null;
            materialThemeMode = ThemeMode.dark;
          default:
            themeData = AppTheme.light(dynamicColorScheme: lightDynamic);
            darkThemeData = AppTheme.dark(dynamicColorScheme: darkDynamic);
            materialThemeMode = ThemeMode.system;
        }

        return MaterialApp.router(
          title: AppConstants.appName,
          theme: themeData,
          darkTheme: darkThemeData,
          themeMode: materialThemeMode,
          routerConfig: _router,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
