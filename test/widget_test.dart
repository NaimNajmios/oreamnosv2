import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:oreamnos/app.dart';
import 'package:oreamnos/data/services/preferences_service.dart';

PreferencesService _createTestPreferencesService(SharedPreferences prefs) {
  const secureStorage = FlutterSecureStorage();
  return PreferencesService(
    prefs: prefs,
    secureStorage: secureStorage,
  );
}

Widget _buildTestApp(PreferencesService preferencesService) {
  return MultiProvider(
    providers: [
      Provider<PreferencesService>.value(value: preferencesService),
    ],
    child: const OreamnosApp(),
  );
}

void main() {
  testWidgets('App renders with bottom navigation', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final sharedPrefs = await SharedPreferences.getInstance();
    final preferencesService = _createTestPreferencesService(sharedPrefs);

    await tester.pumpWidget(_buildTestApp(preferencesService));
    await tester.pumpAndSettle();

    // Verify the app title is displayed in the AppBar
    expect(find.widgetWithText(AppBar, 'Oreamnos'), findsOneWidget);

    // Verify bottom navigation items exist
    expect(find.text('Generate'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // Verify the Generate tab icon
    expect(find.byIcon(Icons.auto_awesome), findsWidgets);
  });

  testWidgets('Bottom navigation switches to Settings', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final sharedPrefs = await SharedPreferences.getInstance();
    final preferencesService = _createTestPreferencesService(sharedPrefs);

    await tester.pumpWidget(_buildTestApp(preferencesService));
    await tester.pumpAndSettle();

    // Tap on Settings tab in bottom nav
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    // Verify Settings screen is shown (section headers are uppercased)
    expect(find.text('AI PROVIDER'), findsOneWidget);
    expect(find.text('APPEARANCE'), findsOneWidget);
  });
}
