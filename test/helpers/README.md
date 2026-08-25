# Test Helpers

- `test_helpers.dart` — Riverpod + secure storage mocks. Replicates `widget_test.dart:16` pattern.
- Phase A will add `lib/core/providers/app_providers.dart` — then `commonOverrides()` will return real overrides.

Usage:
```dart
final prefs = await createMockPrefs();
final prefService = createTestPreferencesService(prefs);
final usage = createTestUsageService(prefs);
await tester.pumpWidget(
  withProviderScope(child: const MyWidget(), overrides: commonOverrides(...)),
);
```
