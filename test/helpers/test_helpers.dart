import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:oreamnos/data/services/preferences_service.dart';
import 'package:oreamnos/data/services/usage_service.dart';
import 'package:oreamnos/domain/services/vision_extractor.dart';

/// Reusable test scaffolding for Riverpod + provider migration.
///
/// Pattern replicates `test/widget_test.dart:16`:
///   `FlutterSecureStorage.setMockInitialValues({})`
///   `SharedPreferences.setMockInitialValues({})`
/// but exposes `ProviderScope` overrides for Riverpod phase.

class FakeVisionExtractor implements IVisionExtractor {
  final String textToReturn;
  FakeVisionExtractor([this.textToReturn = 'extracted fake text']);

  @override
  Future<String> extractText(String imagePath) async => textToReturn;
}

/// Creates a test [PreferencesService] with mocked storage.
PreferencesService createTestPreferencesService(SharedPreferences prefs) {
  FlutterSecureStorage.setMockInitialValues({});
  const secureStorage = FlutterSecureStorage();
  return PreferencesService(prefs: prefs, secureStorage: secureStorage);
}

/// Creates a test [UsageService] backed by mocked SharedPreferences.
UsageService createTestUsageService(SharedPreferences prefs) => UsageService(prefs);

/// Creates mocked [SharedPreferences] with optional initial values.
Future<SharedPreferences> createMockPrefs([
  Map<String, Object> initial = const {},
]) async {
  SharedPreferences.setMockInitialValues(initial);
  return SharedPreferences.getInstance();
}

/// Wraps a widget in a [ProviderScope] with optional overrides — use in
/// `tester.pumpWidget(ProviderScope(child: ...))` for Riverpod tests.
ProviderScope withProviderScope({
  required Widget child,
  List<Override> overrides = const [],
}) {
  return ProviderScope(overrides: overrides, child: child);
}

/// Common overrides for tests that need [PreferencesService]/[UsageService].
List<Override> commonOverrides({
  required PreferencesService preferencesService,
  required UsageService usageService,
}) {
  // Providers will be defined in `lib/core/providers/app_providers.dart` in Phase A.
  // Keeping this helper forward-compatible: returns empty until providers exist.
  return [];
}

// Legacy helper: builds the old MultiProvider test app (for migration baseline).
// Keep until Phase A completes Riverpod migration, then delete.
Widget buildLegacyTestApp(
  PreferencesService preferencesService,
  SharedPreferences prefs, {
  IVisionExtractor? visionExtractor,
}) {
  // Intentionally not importing provider widgets here to avoid new lint issues
  // in Phase 0; tests that need legacy scaffolding should import `test/widget_test.dart:25`
  // directly. This helper is a placeholder for incremental migration.
  throw UnimplementedError(
    'Use test/widget_test.dart:_buildTestApp for legacy MultiProvider scaffolding',
  );
}
