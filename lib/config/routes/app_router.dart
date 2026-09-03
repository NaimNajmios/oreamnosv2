import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:oreamnos/config/theme/app_motion.dart';

import '../../ui/features/generate/views/generate_screen.dart';
import '../../ui/features/settings/views/settings_screen.dart';
import '../../ui/features/shell/views/modern_app_shell.dart';
import '../../ui/features/settings/views/pill_manager_screen.dart';
import '../../ui/features/settings/views/hashtag_manager_screen.dart';
import '../../ui/features/usage/views/usage_screen.dart';
import '../../ui/features/usage/views/session_list_screen.dart';
import '../../ui/features/card_generator/views/card_generator_screen.dart';
import '../../ui/features/generate/views/reading_mode_screen.dart';
import '../../ui/features/settings/views/debug_log_screen.dart';
import '../../data/models/ai_provider.dart';
import '../../domain/models/card_brief.dart';
import '../../domain/models/curated_post.dart';

/// Route path constants.
abstract final class RoutePaths {
  static const String generate = '/generate';
  static const String settings = '/settings';
  static const String readingMode = '/reading-mode';
  static const String pillManager = '/pill-manager';
  static const String hashtagManager = '/hashtag-manager';
  static const String usage = '/usage';
  static const String library = '/library';
  static const String cardGenerator = '/card-generator';
  static const String debugLogs = '/debug-logs';
  static const String sessionHistory = '/sessions';
}

final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Shared fade+slide page transition for shell tabs (280ms).
///
/// Kept separate from [_kickoffPage] (fade+scale for full-screen pushes):
/// the shell Navigator swaps tab pages in place, where a subtle rise reads
/// better than a scale pop.
CustomTransitionPage<T> _kickoffTabPage<T>({required Widget child}) {
  return CustomTransitionPage<T>(
    child: child,
    transitionDuration: AppMotion.transitionSpec,
    reverseTransitionDuration: AppMotion.transitionSpec,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (AppMotion.shouldReduceMotion(context)) return child;
      final curved = CurvedAnimation(
        parent: animation,
        curve: AppMotion.curveTransition,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: curved.drive(
            Tween<Offset>(
              begin: const Offset(0, 0.02),
              end: Offset.zero,
            ),
          ),
          child: child,
        ),
      );
    },
  );
}

/// Shared fade+scale page transition for full-screen routes (280ms).
CustomTransitionPage<T> _kickoffPage<T>({required Widget child}) {
  return CustomTransitionPage<T>(
    child: child,
    transitionDuration: AppMotion.transitionSpec,
    reverseTransitionDuration: AppMotion.transitionSpec,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (AppMotion.shouldReduceMotion(context)) return child;
      final curved = CurvedAnimation(
        parent: animation,
        curve: AppMotion.curveTransition,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.97, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Application router using GoRouter with shell route for 4-tab navigation.
GoRouter createAppRouter({String? initialLocation}) {
  final defaultRoute =
      WidgetsBinding.instance.platformDispatcher.defaultRouteName;
  final effectiveInitialLocation =
      initialLocation ??
      (defaultRoute.isNotEmpty && defaultRoute != '/'
          ? defaultRoute
          : RoutePaths.generate);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: effectiveInitialLocation,
    routes: [
      ShellRoute(
        builder: (context, state, child) => ModernAppShell(child: child),
        routes: [
          GoRoute(
            path: RoutePaths.generate,
            pageBuilder: (context, state) =>
                _kickoffTabPage(child: const GenerateScreen()),
          ),
          GoRoute(
            path: RoutePaths.cardGenerator,
            pageBuilder: (context, state) {
              final extra = state.extra;
              CardBrief? brief;
              bool hasError = false;

              if (extra is CardBrief) {
                brief = extra;
              } else if (extra is Map<String, dynamic>) {
                if (extra['headline'] != null || extra['subtext'] != null) {
                  try {
                    final parsed = CardBrief.fromJson(extra);
                    if (!parsed.isEmpty) brief = parsed;
                  } catch (_) {}
                }
                if (brief == null) {
                  final legacyText = extra['generatedText'] as String?;
                  if (legacyText != null) {
                    final p = extra['provider'];
                    final m = extra['modelId'] as String?;
                    final headline = legacyText.split('\n').first.trim();
                    final subtext = legacyText.trim().length > headline.length
                        ? legacyText
                              .substring(headline.length)
                              .trim()
                              .split('\n')
                              .first
                              .trim()
                        : '';
                    AiProvider provider = AiProvider.gemini;
                    if (p is AiProvider) provider = p;
                    brief = CardBrief(
                      headline: headline.isEmpty ? legacyText.trim() : headline,
                      subtext: subtext,
                      provider: provider,
                      modelId: m ?? '',
                    );
                  }
                }
              }
              // If we navigated to the tab without a brief, we show an empty state instead of an error state.
              // So hasError is only true if they tried to pass an invalid extra that we couldn't parse,
              // but actually let's just default to empty brief if there is no extra.
              return _kickoffTabPage(
                child: CardGeneratorScreen(
                  brief:
                      brief ??
                      const CardBrief(
                        headline: '',
                        subtext: '',
                        provider: AiProvider.gemini,
                        modelId: '',
                      ),
                  hasError: hasError,
                ),
              );
            },
          ),
          GoRoute(
            path: RoutePaths.usage,
            pageBuilder: (context, state) =>
                _kickoffTabPage(child: const UsageScreen()),
          ),
          GoRoute(
            path: RoutePaths.settings,
            pageBuilder: (context, state) =>
                _kickoffTabPage(child: const SettingsScreen()),
          ),
        ],
      ),
      GoRoute(
        path: RoutePaths.readingMode,
        pageBuilder: (context, state) {
          final extra = state.extra;
          Widget child;
          if (extra is String) {
            child = ReadingModeScreen(content: extra);
          } else if (extra is Map<String, dynamic> &&
              extra['curatedPost'] != null) {
            final cp = extra['curatedPost'];
            if (cp is CuratedPost) {
              child = ReadingModeScreen(
                content:
                    extra['copyText'] as String? ?? cp.toPlainTextFiltered(),
                curatedPost: cp,
              );
            } else {
              final content =
                  extra['copyText'] as String? ??
                  state.uri.queryParameters['content'] ??
                  '';
              child = ReadingModeScreen(content: content);
            }
          } else if (extra is CuratedPost) {
            // Fallback for CuratedPost directly
            child = ReadingModeScreen(
              content: extra.toPlainTextFiltered(),
              curatedPost: extra,
            );
          } else {
            final content =
                extra as String? ?? state.uri.queryParameters['content'] ?? '';
            child = ReadingModeScreen(content: content);
          }
          return _kickoffPage(child: child);
        },
      ),
      GoRoute(
        path: RoutePaths.pillManager,
        pageBuilder: (context, state) =>
            _kickoffPage(child: const PillManagerScreen()),
      ),
      GoRoute(
        path: RoutePaths.hashtagManager,
        pageBuilder: (context, state) =>
            _kickoffPage(child: const HashtagManagerScreen()),
      ),

      GoRoute(
        path: RoutePaths.debugLogs,
        pageBuilder: (context, state) =>
            _kickoffPage(child: const DebugLogScreen()),
      ),
      GoRoute(
        path: RoutePaths.sessionHistory,
        pageBuilder: (context, state) =>
            _kickoffPage(child: const SessionListScreen()),
      ),
    ],
  );
}
