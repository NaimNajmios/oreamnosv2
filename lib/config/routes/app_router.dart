import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../ui/features/generate/views/generate_screen.dart';
import '../../ui/features/settings/views/settings_screen.dart';
import '../../ui/features/shell/views/modern_app_shell.dart';
import '../../ui/features/settings/views/pill_manager_screen.dart';
import '../../ui/features/settings/views/hashtag_manager_screen.dart';
import '../../ui/features/usage/views/usage_screen.dart';
import '../../ui/features/card_generator/views/card_generator_screen.dart';
import '../../ui/features/generate/views/reading_mode_screen.dart';
import '../../ui/features/settings/views/debug_log_screen.dart';
import '../../data/models/ai_provider.dart';
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
}

final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Application router using GoRouter with shell route for 3-tab navigation.
GoRouter createAppRouter() {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: RoutePaths.generate,
    routes: [
      ShellRoute(
        builder: (context, state, child) => ModernAppShell(child: child),
        routes: [
          GoRoute(
            path: RoutePaths.generate,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: GenerateScreen(),
            ),
          ),
          GoRoute(
            path: RoutePaths.usage,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: UsageScreen(),
            ),
          ),
          GoRoute(
            path: RoutePaths.settings,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: RoutePaths.readingMode,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is String) {
            return ReadingModeScreen(content: extra);
          }
          if (extra is Map<String, dynamic> && extra['curatedPost'] != null) {
            final cp = extra['curatedPost'];
            if (cp is CuratedPost) return ReadingModeScreen(content: cp.rawMarkdown, curatedPost: cp);
          }
          // Fallback for CuratedPost directly
          if (extra is CuratedPost) return ReadingModeScreen(content: extra.rawMarkdown, curatedPost: extra);
          final content = extra as String? ?? '';
          return ReadingModeScreen(content: content);
        },
      ),
      GoRoute(
        path: RoutePaths.pillManager,
        builder: (context, state) => const PillManagerScreen(),
      ),
      GoRoute(
        path: RoutePaths.hashtagManager,
        builder: (context, state) => const HashtagManagerScreen(),
      ),
      GoRoute(
        path: RoutePaths.cardGenerator,
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>;
          return CardGeneratorScreen(
            generatedText: args['generatedText'] as String,
            provider: args['provider'] as AiProvider,
            apiKey: args['apiKey'] as String? ?? '',
            modelId: args['modelId'] as String,
          );
        },
      ),
      GoRoute(
        path: RoutePaths.debugLogs,
        builder: (context, state) => const DebugLogScreen(),
      ),
    ],
  );
}
