import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/constants.dart';
import 'config/routes/app_router.dart';
import 'config/theme/app_theme.dart';
import 'domain/models/app_theme_mode.dart';
import 'domain/models/curated_post.dart';

import 'ui/features/settings/view_models/settings_view_model.dart';
import 'ui/features/generate/view_models/generate_view_model.dart';
import 'data/services/share_intent_service.dart';
import 'data/services/notification_service.dart';

/// Root application widget.
class OreamnosApp extends ConsumerStatefulWidget {
  const OreamnosApp({super.key});

  @override
  ConsumerState<OreamnosApp> createState() => _OreamnosAppState();
}

class _OreamnosAppState extends ConsumerState<OreamnosApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createAppRouter();

    // Request notification permissions after app launch
    Future.microtask(() {
      try {
        NotificationService().requestPermission();
      } catch (_) {}
    });

    // Route notification actions (tone quick chooser, open, copy) — must be set after DI.
    NotificationService().onAction = (payload, actionId) async {
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

    ShareIntentService().onSharedTextReceived = (text) async {
      if (!mounted) return;

      _router.go(RoutePaths.generate);
      ref.read(generateViewModelProvider.notifier).setPendingInput(text);

      Future.microtask(() {
        if (mounted) {
          ref.read(generateViewModelProvider.notifier).generatePost(text);
        }
      });
    };
    ShareIntentService().initialize();
  }

  @override
  void dispose() {
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
