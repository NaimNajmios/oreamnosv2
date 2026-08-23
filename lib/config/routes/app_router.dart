import 'package:go_router/go_router.dart';

import '../../ui/features/generate/views/generate_screen.dart';
import '../../ui/features/settings/views/settings_screen.dart';
import '../../ui/features/shell/views/app_shell.dart';

/// Route path constants.
abstract final class RoutePaths {
  static const String generate = '/generate';
  static const String settings = '/settings';
  // Future routes:
  // static const String usage = '/usage';
  // static const String cardGenerator = '/card-generator';
  // static const String sessions = '/sessions';
}

/// Application router using GoRouter with shell route for bottom navigation.
GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: RoutePaths.generate,
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: RoutePaths.generate,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: GenerateScreen(),
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
    ],
  );
}
