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
    final onSurface = theme.colorScheme.onSurface;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: theme.colorScheme.outline, width: 2),
          ),
        ),
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (index) => _onTabTapped(context, index),
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.auto_awesome_outlined, color: onSurface),
              selectedIcon: Icon(Icons.auto_awesome_rounded, color: onSurface),
              label: 'GENERATE',
            ),
            NavigationDestination(
              icon: Icon(Icons.palette_outlined, color: onSurface),
              selectedIcon: Icon(Icons.palette_rounded, color: onSurface),
              label: 'STUDIO',
            ),
            NavigationDestination(
              icon: Icon(Icons.tune_outlined, color: onSurface),
              selectedIcon: Icon(Icons.tune_rounded, color: onSurface),
              label: 'SETTINGS',
            ),
          ],
        ),
      ),
    );
  }
}
