import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'config/constants.dart';
import 'config/routes/app_router.dart';
import 'config/theme/app_theme.dart';
import 'domain/models/app_theme_mode.dart';

import 'ui/features/settings/view_models/settings_view_model.dart';
import 'ui/features/generate/view_models/generate_view_model.dart';
import 'data/services/share_intent_service.dart';
import 'ui/features/share/share_bottom_sheet.dart';
import 'ui/core/widgets/kickoff_loading_indicator.dart';
import 'data/services/notification_service.dart';

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

    // Request notification permissions after app launch
    Future.microtask(() {
      try {
        NotificationService().requestPermission();
      } catch (_) {}
    });

    ShareIntentService().onSharedTextReceived = (text) {
      if (!mounted) return;
      
      final currentContext = rootNavigatorKey.currentContext;
      if (currentContext != null) {
        showModalBottomSheet(
          context: currentContext,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => ShareBottomSheet(initialContent: text),
        );
      } else {
        // Fallback
        context.read<GenerateViewModel>().setPendingInput(text);
        _router.go(RoutePaths.generate);
      }
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
    final settingsViewModel = context.watch<SettingsViewModel>();
    
    if (!settingsViewModel.isInitialized) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: KickoffLoadingIndicator(size: 48)),
        ),
      );
    }

    final themeMode = settingsViewModel.themeMode;

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
            themeData = AppTheme.solarizedLight(dynamicColorScheme: lightDynamic);
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
          case AppThemeMode.system:
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
