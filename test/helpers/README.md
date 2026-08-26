# Test Helpers

- `test_helpers.dart:48` — mocks via `FlutterSecureStorage.setMockInitialValues({})` + `SharedPreferences.setMockInitialValues({})` + `ProviderScope` overrides + `getIt` `PreferencesService`/`UsageService`/`LogService` registration `lib/core/di/injection.dart:13` + `injection.config.dart:42` (replaces deleted `lib/core/providers/app_providers.dart` → `injection.dart`/`register_module.dart`).
- Pattern in `test/widget_test.dart:16` `withProviderScope` + `test/generate_view_model_test.dart:45` `getIt.allowReassignment` — to be replaced by pure `Notifier` overrides in Phase D.

Usage:
```dart
final prefs = await createMockPrefs();
final prefService = createTestPreferencesService(prefs);
final usage = createTestUsageService(prefs);
await tester.pumpWidget(
  withProviderScope(child: const MyWidget(), overrides: commonOverrides(...)),
);
```
