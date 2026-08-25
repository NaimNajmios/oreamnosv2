# AGENTS.md — oreamnos

## Stack
- Single-package Flutter app (`pubspec.yaml:1`, `project_type: app` in `.metadata`). Dart `^3.13.1`, Flutter `3.47.1` stable.
- State: `flutter_riverpod 2.6.1` + `ProviderScope` (`lib/main.dart:42`) and `provider` + `ChangeNotifier` compatibility layer (`lib/app.dart:61`).
- Routing: `go_router` `14.8.1` with `ShellRoute` + `ModernAppShell`.
- Network: `dio 5.11.0` pooled `ApiClient` (`lib/core/network/api_client.dart`) with 4 interceptors (Auth, ErrorMapping, Retry, Logging).
- Codegen: `freezed` & `json_serializable` for sealed `CardData` model.

## Commands
```bash
flutter pub get
flutter run                                               # local device/emulator
flutter analyze                                           # lints via analysis_options.yaml (0 issues)
flutter test                                              # run all 75 tests across test/
flutter test test/widget_test.dart                         # single test file
flutter test test/unit/renderers_test.dart                # test all 17 card renderers
dart run build_runner build --delete-conflicting-outputs  # codegen for Freezed / json_serializable
dart run test_scraper.dart                                # ad-hoc URL scrape probe (root)
dart run test_isurl.dart                                  # ad-hoc URI parse probe
```

## Architecture
- **Entrypoints**: `lib/main.dart:20` (`ProviderScope` + DI + `MultiProvider` init: `SharedPreferences`, `FlutterSecureStorage` with `encryptedSharedPreferences:true`, `UsageService`, `NotificationService`, `QuickSettingsService`) $\rightarrow$ `lib/app.dart:17` `OreamnosApp` (DynamicColor, theme switcher with 7 themes, `ShareIntentService` bottom sheet).
- **Routing**: `lib/config/routes/app_router.dart:16` — `RoutePaths` + `rootNavigatorKey`. `ShellRoute` tabs: `/generate`, `/usage` (Library), `/settings`. Full-screen routes outside shell: `/reading-mode`, `/pill-manager`, `/hashtag-manager`, `/card-generator`, `/debug-logs`.
- **Card Generator**: 16 sealed template variants in `lib/domain/models/card_data.dart` with dedicated renderers in `lib/ui/features/card_generator/widgets/renderers/` dispatched via `CardCanvasDispatcher`. Schema definitions in `lib/domain/services/card_prompt_manager.dart` and parsing in `lib/data/services/card_data_extractor.dart`.
- **AI Curators**: `IContentCurator` (`lib/domain/services/content_curator.dart`) implemented by `GeminiCurator` and `OpenAICompatibleCurator` (`lib/data/services/curators/`) using pooled `ApiClient.dio` connections and `JsonCleaner.decodeIsolate`.
- **Vision Extraction**: `IVisionExtractor` (`lib/domain/services/vision_extractor.dart`) $\rightarrow$ `MLKitVisionExtractor` using `google_mlkit_text_recognition`.
- **Secrets**: `PreferencesService` (`lib/data/services/preferences_service.dart`) stores API keys in `flutter_secure_storage` and non-sensitive prefs in `shared_preferences`. Never log keys.

## Testing & CI
- **Automated CI**: GitHub Actions workflow at `.github/workflows/ci.yaml` runs `flutter analyze` and `flutter test` on PRs and pushes to `main`.
- **Mocking Strategy**: Real device plugins (`google_mlkit_text_recognition`, `gal`, `image_picker`, `quick_settings`, `flutter_local_notifications`) are mocked in tests using `FlutterSecureStorage.setMockInitialValues({})` and `SharedPreferences.setMockInitialValues({})` (see `test/helpers/test_helpers.dart`).
- **Test Suites**: 75 tests spanning `test/unit/` (Curators, Renderers, UsageService, LogService, DelightWidgets, Interceptors, JsonCleaner, CardDataExtractor) and `test/widget_test.dart`.
