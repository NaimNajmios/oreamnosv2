import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:oreamnos/app.dart';
import 'package:oreamnos/data/services/preferences_service.dart';
import 'package:oreamnos/data/services/usage_service.dart';
import 'package:oreamnos/data/services/export_service.dart';
import 'package:oreamnos/data/services/card_data_extractor.dart';
import 'package:oreamnos/ui/features/settings/view_models/settings_view_model.dart';
import 'package:oreamnos/ui/features/generate/view_models/generate_view_model.dart';
import 'package:oreamnos/ui/features/card_generator/view_models/card_generator_view_model.dart';

PreferencesService _createTestPreferencesService(SharedPreferences prefs) {
  FlutterSecureStorage.setMockInitialValues({});
  const secureStorage = FlutterSecureStorage();
  return PreferencesService(
    prefs: prefs,
    secureStorage: secureStorage,
  );
}

Widget _buildTestApp(PreferencesService preferencesService, SharedPreferences prefs) {
  final usageService = UsageService(prefs);

  return MultiProvider(
    providers: [
      Provider<PreferencesService>.value(value: preferencesService),
      ChangeNotifierProvider<UsageService>.value(value: usageService),
      ChangeNotifierProvider<SettingsViewModel>(
        create: (context) => SettingsViewModel(context.read<PreferencesService>()),
      ),
      ChangeNotifierProxyProvider<SettingsViewModel, GenerateViewModel>(
        create: (context) => GenerateViewModel(
          context.read<SettingsViewModel>(),
          context.read<UsageService>(),
        ),
        update: (context, settings, previous) =>
            previous ??
            GenerateViewModel(
              settings,
              context.read<UsageService>(),
            ),
      ),
      Provider<ExportService>(create: (_) => ExportService()),
      Provider<CardDataExtractor>(create: (_) => CardDataExtractor()),
      ChangeNotifierProvider<CardGeneratorViewModel>(
        create: (context) => CardGeneratorViewModel(
          extractor: context.read<CardDataExtractor>(),
          exportService: context.read<ExportService>(),
        ),
      ),
    ],
    child: const OreamnosApp(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App renders with 4-tab navigation bar', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final sharedPrefs = await SharedPreferences.getInstance();
    final preferencesService = _createTestPreferencesService(sharedPrefs);

    await tester.pumpWidget(_buildTestApp(preferencesService, sharedPrefs));
    await tester.pumpAndSettle();

    // Verify the app title in AppBar
    expect(find.widgetWithText(AppBar, 'Oreamnos'), findsOneWidget);

    // Verify 4 navigation destinations
    expect(find.text('Generate'), findsOneWidget);
    expect(find.text('Cards'), findsOneWidget);
    expect(find.text('Usage'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // Verify the Generate CTA button
    expect(find.text('Generate Post'), findsOneWidget);
  });

  testWidgets('Navigation bar switches to Settings and shows grouped sections', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final sharedPrefs = await SharedPreferences.getInstance();
    final preferencesService = _createTestPreferencesService(sharedPrefs);

    await tester.pumpWidget(_buildTestApp(preferencesService, sharedPrefs));
    await tester.pumpAndSettle();

    // Tap on Settings tab in NavigationBar
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    // Verify Settings screen sections
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('AI Provider'), findsOneWidget);

    // Scroll until Post Settings section is visible
    await tester.scrollUntilVisible(
      find.text('Post Settings'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Post Settings'), findsOneWidget);

    // Scroll until Advanced section is visible
    await tester.scrollUntilVisible(
      find.text('Advanced'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Advanced'), findsOneWidget);
  });

  testWidgets('Navigation bar switches to Cards tab', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final sharedPrefs = await SharedPreferences.getInstance();
    final preferencesService = _createTestPreferencesService(sharedPrefs);

    await tester.pumpWidget(_buildTestApp(preferencesService, sharedPrefs));
    await tester.pumpAndSettle();

    // Tap on Cards tab in NavigationBar
    await tester.tap(find.text('Cards'));
    await tester.pumpAndSettle();

    // Verify Card Studio title (the screen title remains Card Studio)
    expect(find.text('Card Studio'), findsOneWidget);
  });
}
