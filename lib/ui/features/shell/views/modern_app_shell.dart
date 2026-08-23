import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:oreamnos/config/routes/app_router.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';

/// Modern App Shell with Material 3 NavigationBar (Generate, Library, Settings).
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

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => _onTabTapped(context, index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome_rounded),
            label: 'Generate',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics_rounded),
            label: 'Library',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
