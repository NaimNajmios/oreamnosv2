import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dart:convert';

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

  testWidgets('App renders with 5-tab navigation bar', (
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

    // Verify 5 navigation destinations
    expect(find.text('Generate'), findsOneWidget);
    expect(find.text('Cards'), findsOneWidget);
    expect(find.text('Publish'), findsOneWidget);
    expect(find.text('Usage'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // Verify the Generate CTA button
    expect(find.text('Generate Post'), findsOneWidget);

    // Publish opens the hub.
    await tester.tap(find.text('Publish'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Publish'), findsOneWidget);
    expect(find.text('Connect a Page to start'), findsOneWidget);
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

      // Verify Settings screen sections (SectionHeader renders uppercase)
      expect(find.text('APPEARANCE'), findsOneWidget);
      expect(find.text('AI PROVIDER'), findsOneWidget);

      // Scroll until Post Settings section is visible
      await tester.scrollUntilVisible(
        find.text('POST SETTINGS'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('POST SETTINGS'), findsOneWidget);

      // Scroll until Advanced section is visible
      await tester.scrollUntilVisible(
        find.text('ADVANCED'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('ADVANCED'), findsOneWidget);
      // Publishing moved to its own bottom-nav tab.
      expect(find.text('Page publishing'), findsNothing);
    },
  );

  testWidgets('Publish tab shows the connected Page and create CTA', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'facebook_pages': jsonEncode([
        {'id': 'p1', 'name': 'Trace Football', 'pictureUrl': ''},
      ]),
      'facebook_active_page': 'p1',
    });
    final sharedPrefs = await SharedPreferences.getInstance();
    final preferencesService = _createTestPreferencesService(sharedPrefs);

    await tester.pumpWidget(
      await _buildTestApp(preferencesService, sharedPrefs),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Publish'));
    await tester.pumpAndSettle();

    expect(find.text('Trace Football'), findsOneWidget);
    expect(find.text('Create a post'), findsOneWidget);
    expect(find.text('New post'), findsWidgets);
  });

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
