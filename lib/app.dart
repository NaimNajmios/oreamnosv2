import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'config/constants.dart';
import 'config/routes/app_router.dart';
import 'config/theme/app_theme.dart';
import 'data/services/preferences_service.dart';
import 'domain/models/app_theme_mode.dart';

/// Root application widget.
class OreamnosApp extends StatefulWidget {
  const OreamnosApp({super.key});

  @override
  State<OreamnosApp> createState() => _OreamnosAppState();
}

class _OreamnosAppState extends State<OreamnosApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createAppRouter();
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prefs = context.read<PreferencesService>();
    final themeMode = prefs.themeMode;

    final ThemeData themeData;
    final ThemeData? darkThemeData;
    final ThemeMode materialThemeMode;

    switch (themeMode) {
      case AppThemeMode.light:
        themeData = AppTheme.light();
        darkThemeData = null;
        materialThemeMode = ThemeMode.light;
      case AppThemeMode.dark:
        themeData = AppTheme.dark();
        darkThemeData = null;
        materialThemeMode = ThemeMode.dark;
      case AppThemeMode.deepBlue:
        // Deep Blue is a custom dark theme — force dark mode
        themeData = AppTheme.deepBlue();
        darkThemeData = null;
        materialThemeMode = ThemeMode.dark;
      case AppThemeMode.system:
        themeData = AppTheme.light();
        darkThemeData = AppTheme.dark();
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
  }
}
