import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart' as legacy_provider;
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/providers/app_providers.dart';
import 'data/services/preferences_service.dart';
import 'data/services/usage_service.dart';

import 'ui/features/settings/view_models/settings_view_model.dart';
import 'ui/features/generate/view_models/generate_view_model.dart';
import 'data/services/export_service.dart';
import 'data/services/card_data_extractor.dart';
import 'domain/services/vision_extractor.dart';
import 'data/services/ml_kit_vision_extractor.dart';
import 'ui/features/card_generator/view_models/card_generator_view_model.dart';
import 'data/services/notification_service.dart';
import 'data/services/quick_settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences before app starts
  final sharedPrefs = await SharedPreferences.getInstance();

  await NotificationService().init();
  await NotificationService().requestPermission();

  await QuickSettingsService.init();

  const secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  final preferencesService = PreferencesService(
    prefs: sharedPrefs,
    secureStorage: secureStorage,
  );

  final usageService = UsageService(sharedPrefs);

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPrefs),
        secureStorageProvider.overrideWithValue(secureStorage),
      ],
      child: legacy_provider.MultiProvider(
        providers: [
          legacy_provider.Provider<PreferencesService>.value(value: preferencesService),
          legacy_provider.ChangeNotifierProvider<UsageService>.value(value: usageService),
          legacy_provider.ChangeNotifierProvider<SettingsViewModel>(
            create: (context) => SettingsViewModel(context.read<PreferencesService>()),
          ),
          legacy_provider.Provider<IVisionExtractor>(create: (_) => MLKitVisionExtractor()),
          legacy_provider.ChangeNotifierProxyProvider2<SettingsViewModel, IVisionExtractor, GenerateViewModel>(
            create: (context) => GenerateViewModel(
              context.read<SettingsViewModel>(),
              context.read<UsageService>(),
              context.read<IVisionExtractor>(),
            ),
            update: (context, settings, visionExtractor, previous) =>
                previous ??
                GenerateViewModel(
                  settings,
                  context.read<UsageService>(),
                  visionExtractor,
                ),
          ),
          legacy_provider.Provider<ExportService>(create: (_) => ExportService()),
          legacy_provider.Provider<CardDataExtractor>(create: (_) => CardDataExtractor()),
          legacy_provider.ChangeNotifierProvider<CardGeneratorViewModel>(
            create: (context) => CardGeneratorViewModel(
              extractor: context.read<CardDataExtractor>(),
              exportService: context.read<ExportService>(),
            ),
          ),
        ],
        child: const OreamnosApp(),
      ),
    ),
  );
}
