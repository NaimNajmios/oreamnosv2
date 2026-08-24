import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:oreamnos/config/routes/app_router.dart';
import 'package:oreamnos/config/theme/app_colors.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';

/// Modern App Shell with Material 3 NavigationBar (Generate, Usage, Settings).
class ModernAppShell extends StatelessWidget {
  const ModernAppShell({super.key, required this.child});

  final Widget child;

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith(RoutePaths.settings)) return 2;
    if (location.startsWith(RoutePaths.usage) || location.startsWith('/library')) return 1;
    return 0; // default to generate
  }

  void _onTabTapped(BuildContext context, int index) {
    Haptics.selectionClick();
    switch (index) {
      case 0:
        context.go(RoutePaths.generate);
      case 1:
        context.go(RoutePaths.usage);
      case 2:
        context.go(RoutePaths.settings);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final amber = isDark ? AppColors.darkAmber : AppColors.lightAmber;
    final violet = isDark ? AppColors.darkViolet : AppColors.lightViolet;
    final teal = isDark ? AppColors.darkTeal : AppColors.lightTeal;
    // Per-tab hue for selected state — flat tint, not gradient
    final indicatorColors = [amber.withValues(alpha: 0.18), violet.withValues(alpha: 0.18), teal.withValues(alpha: 0.18)];
    final iconColors = [amber, violet, teal];

    return Scaffold(
      body: child,
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          navigationBarTheme: Theme.of(context).navigationBarTheme.copyWith(
                indicatorColor: indicatorColors[currentIndex],
              ),
        ),
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (index) => _onTabTapped(context, index),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.auto_awesome_outlined),
              selectedIcon: Icon(Icons.auto_awesome_rounded, color: iconColors[0]),
              label: 'Generate',
            ),
            NavigationDestination(
              icon: const Icon(Icons.analytics_outlined),
              selectedIcon: Icon(Icons.analytics_rounded, color: iconColors[1]),
              label: 'Usage',
            ),
            NavigationDestination(
              icon: const Icon(Icons.tune_outlined),
              selectedIcon: Icon(Icons.tune_rounded, color: iconColors[2]),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
