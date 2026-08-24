# AGENTS.md — oreamnos

## Stack
- Single-package Flutter app (`pubspec.yaml:1`, `project_type: app` in `.metadata`). Dart `^3.13.1`, Flutter `3.47.1` stable.
- State: `provider` + `ChangeNotifier` (wired in `lib/main.dart:42`, `lib/app.dart:61`). Routing: `go_router` `14.8.1` with `ShellRoute` + `ModernAppShell`.

## Commands
```bash
flutter pub get
flutter run                          # local device/emulator
flutter analyze                       # lints via package:flutter_lints/flutter.yaml (analysis_options.yaml:10)
flutter test                          # widget tests in test/
flutter test test/widget_test.dart    # single file
dart run build_runner build --delete-conflicting-outputs  # codegen for json_serializable (pubspec.yaml:60-61); no .g.dart currently committed
dart run test_scraper.dart            # ad-hoc URL scrape probe (root, not a flutter test)
dart run test_isurl.dart              # ad-hoc URI parse probe
```

## Architecture
- Entrypoints: `lib/main.dart:20` (DI + `MultiProvider` init: `SharedPreferences`, `FlutterSecureStorage` with `encryptedSharedPreferences:true`, `UsageService`, `NotificationService`, `QuickSettingsService`) → `lib/app.dart:17` `OreamnosApp` (DynamicColor, theme switch, `ShareIntentService` bottom sheet).
- `lib/config/routes/app_router.dart:16` — `RoutePaths` + `rootNavigatorKey`. `ShellRoute` tabs: `/generate`, `/usage` (Library), `/settings`. Full-screen routes outside shell: `/reading-mode`, `/pill-manager`, `/hashtag-manager`, `/card-generator` (requires `state.extra` map with `generatedText`+`provider`+`apiKey`+`modelId`), `/debug-logs`.
- `lib/domain/` models (`card_data.dart`, `usage_log.dart`, `hashtag_group.dart`, `custom_pill.dart`) are manual `fromJson`/`toJson` + `Equatable` — `json_annotation` is declared but not actively generated; add `@JsonSerializable` before relying on build_runner.
- `lib/domain/services/content_curator.dart:3` `IContentCurator` + `lib/data/services/curators/` (`gemini_curator.dart`, `openai_compatible_curator.dart`) via `lib/data/services/curator_factory.dart:3`. `lib/domain/services/vision_extractor.dart:3` `IVisionExtractor` → `lib/data/services/ml_kit_vision_extractor.dart`.
- Secrets: `PreferencesService` (`lib/data/services/preferences_service.dart`) stores API keys in `flutter_secure_storage`, prefs in `shared_preferences`. Never log keys.

## Gotchas
- Many features require real device: `receive_sharing_intent`, `google_mlkit_text_recognition`, `gal`, `image_picker`, `quick_settings` (tile: `lib/data/services/quick_settings_service.dart`), `flutter_local_notifications`. Widget tests mock these — see `test/widget_test.dart:16` `FlutterSecureStorage.setMockInitialValues({})` + `SharedPreferences.setMockInitialValues({})`. Replicate that pattern for new tests; `GenerateViewModel` in app needs `IVisionExtractor` (`main.dart:50`) — widget_test omits it (older 2-arg ctor), update test provider graph when touching `GenerateViewModel`.
- `test/generate_icon_test.dart:7` is not a unit test — it renders a `Canvas` and writes `icon/icon.png`. Run in isolation; don't count on it for CI coverage.
- Icon/splash are generated assets: `flutter_launcher_icons` (`icon/icon.png` → `launcher_icon`) and `flutter_native_splash` (`#1C1C1C`) in `pubspec.yaml:68-77`.
- `lib/data/services/web_scraper_service.dart` uses `package:html` + `http` with custom User-Agent (see `test_scraper.dart:9` pattern). Network calls need mock in tests.
- No CI workflows / pre-commit hooks in repo. Verify manually with `flutter analyze && flutter test` before PR.
