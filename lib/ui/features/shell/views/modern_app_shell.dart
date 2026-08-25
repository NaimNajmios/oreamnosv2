import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:oreamnos/config/routes/app_router.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';

/// Modern App Shell with Material 3 NavigationBar (Generate, Card Studio, Settings).
class ModernAppShell extends StatelessWidget {
  const ModernAppShell({super.key, required this.child});

  final Widget child;

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith(RoutePaths.settings)) return 2;
    if (location.startsWith(RoutePaths.cardGenerator)) return 1;
    return 0; // default to generate
  }

  void _onTabTapped(BuildContext context, int index) {
    Haptics.selectionClick();
    switch (index) {
      case 0:
        context.go(RoutePaths.generate);
      case 1:
        context.go(RoutePaths.cardGenerator);
      case 2:
        context.go(RoutePaths.settings);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentIndex = _currentIndex(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => _onTabTapped(context, index),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome_rounded, color: primary),
            label: 'Generate',
          ),
          NavigationDestination(
            icon: const Icon(Icons.palette_outlined),
            selectedIcon: Icon(Icons.palette_rounded, color: primary),
            label: 'Studio',
          ),
          NavigationDestination(
            icon: const Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune_rounded, color: primary),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

}
