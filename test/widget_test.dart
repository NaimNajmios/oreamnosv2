import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:oreamnos/app.dart';
import 'package:oreamnos/data/services/preferences_service.dart';
import 'package:oreamnos/data/services/usage_service.dart';
import 'package:oreamnos/data/services/export_service.dart';
import 'package:oreamnos/data/services/card_data_extractor.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oreamnos/core/di/injection.dart';

PreferencesService _createTestPreferencesService(SharedPreferences prefs) {
  FlutterSecureStorage.setMockInitialValues({});
  const secureStorage = FlutterSecureStorage();
  return PreferencesService(prefs: prefs, secureStorage: secureStorage);
}

Future<Widget> _buildTestApp(
  PreferencesService preferencesService,
  SharedPreferences prefs,
) async {
  final usageService = UsageService(prefs);

  await getIt.reset();
  await configureDependencies();
  getIt.allowReassignment = true;
  getIt.registerLazySingleton<PreferencesService>(() => preferencesService);
  getIt.registerLazySingleton<UsageService>(() => usageService);
  getIt.registerLazySingleton<ExportService>(() => ExportService());
  getIt.registerLazySingleton<CardDataExtractor>(() => CardDataExtractor());

  return const ProviderScope(child: OreamnosApp());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App renders with 4-tab navigation bar', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final sharedPrefs = await SharedPreferences.getInstance();
    final preferencesService = _createTestPreferencesService(sharedPrefs);

    await tester.pumpWidget(
      await _buildTestApp(preferencesService, sharedPrefs),
    );
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

  testWidgets(
    'Navigation bar switches to Settings and shows grouped sections',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final sharedPrefs = await SharedPreferences.getInstance();
      final preferencesService = _createTestPreferencesService(sharedPrefs);

      await tester.pumpWidget(
        await _buildTestApp(preferencesService, sharedPrefs),
      );
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
    },
  );

  testWidgets('Navigation bar switches to Cards tab', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final sharedPrefs = await SharedPreferences.getInstance();
    final preferencesService = _createTestPreferencesService(sharedPrefs);

    await tester.pumpWidget(
      await _buildTestApp(preferencesService, sharedPrefs),
    );
    await tester.pumpAndSettle();

    // Tap on Cards tab in NavigationBar
    await tester.tap(find.text('Cards'));
    await tester.pumpAndSettle();

    // Verify Card Studio title (the screen title remains Card Studio)
    expect(find.text('Card Studio'), findsOneWidget);
  });
}
