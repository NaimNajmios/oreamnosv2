import 'package:flutter/material.dart';

import 'modern_app_shell.dart';

/// Legacy AppShell alias forwarding to ModernAppShell.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ModernAppShell(child: child);
  }
}
