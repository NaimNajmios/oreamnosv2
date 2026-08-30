# AGENTS.md — oreamnos

## Stack
- Single-package Flutter app (`pubspec.yaml:1`, `project_type: app` in `.metadata`). Dart `^3.13.1`, Flutter `3.47.1` stable.
- State: `flutter_riverpod 2.6.1` + `ProviderScope` (`lib/main.dart:26` `ProviderScope+configureDependencies()`) — `Notifier` pure `GenerateViewModel extends Notifier<GenerateUiState>` `lib/ui/features/generate/view_models/generate_view_model.dart:49` + `CardGeneratorViewModel extends Notifier<CardGeneratorState>` `lib/ui/features/card_generator/view_models/card_generator_view_model.dart:36` + `SettingsNotifier extends Notifier<SettingsState>` `lib/ui/features/settings/view_models/settings_view_model.dart:11` (migrated from `ChangeNotifier`).
- Routing: `go_router` `14.8.1` `GoRouter` `lib/config/routes/app_router.dart:16` — 4 `ShellRoute` tabs (`/generate`, `/card-generator`, `/usage`, `/settings`) `ModernAppShell:52` 60dp + 5 full-screen (`/reading-mode`, `/pill-manager`, `/hashtag-manager`, `/debug-logs`, `/sessions`).
- Network: `dio 5.11.0` pooled `ApiClient` `lib/core/network/api_client.dart:13` `BaseOptions 15s` + 4 interceptors `Auth(extra→?key/Bearer)→Retry(4×500ms→60s jitter Retry-After)→ErrorMapping(429→RateLimitFailure:15)→Logging(if kDebugMode)` + `IContentRepository` `Result<CuratedPost>` fold + 30s timeout `generate_view_model.dart:370` + strict `jsonSchema` `GenerationPromptManager.jsonSchema` wired to Gemini `responseSchema`/`OpenAI json_schema`; side-channel `TokenUsageSideChannel` `lib/data/services/token_usage_side_channel.dart:1` for `usageMetadata/total_tokens` → `UsageService`. `WebScraperService:10` + `ProviderApiService:17` via same pool (`http` probe moved `tool/dev/scrape_probe.dart`).
- DI: `get_it`+`injectable` `lib/core/di/injection.dart:13` `getIt.init()` + `register_module.dart` → `lib/core/di/injection.config.dart:50` `ApiClient`, `TokenUsageSideChannel`, `CardDataExtractor`, `ExportService`, `IContentRepository`/`ICardRepository`/`ISettingsRepository`/`IUsageRepository`, `WebScraperService`, `ProviderApiService`, `PreferencesService`, `LogService`, `UsageService`.
- Codegen: `freezed 4.0.0` + `injectable` for sealed `CardData` 17 `lib/domain/models/card_data.dart:104` (+`SparseCard:323`) / `CardTemplate` 17 `lib/domain/models/card_template.dart:3` + `CardConfig` 28 `lib/domain/models/card_config.dart:47` (10 `ImagePosition`,5 `ExportSize`,5 `PhotoFilter`) + `GenerateUiState` `lib/ui/features/generate/view_models/generate_state.dart:10` + `CardGeneratorState` `lib/ui/features/card_generator/view_models/card_generator_state.dart:16`.

## Commands
```bash
flutter pub get
flutter run                                               # local device/emulator
dart format --output=none --set-exit-if-changed .         # CI gate (must be 0 changed)
flutter analyze                                           # lints via analysis_options.yaml (0 issues)
flutter test --coverage                                   # run all 82 tests across test/ (17 renderers via CardCanvasDispatcher)
flutter test test/widget_test.dart                         # single test file
flutter test test/unit/renderers_test.dart                # test all 17 card renderers
dart run build_runner build --delete-conflicting-outputs  # codegen for Freezed / json_serializable / injectable
# See docs/architecture.md, docs/design-system-threads.md, docs/baseline-phaseB.md
```

## Architecture
- **Entrypoints**: `lib/main.dart:20` `configureDependencies()` + `NotificationService.init()` + `QuickSettingsService.init()` → `ProviderScope` → `lib/app.dart:17` `OreamnosApp extends ConsumerStatefulWidget` (`DynamicColorBuilder:80` theme switcher 9 modes `lib/domain/models/app_theme_mode.dart:2` horizontally scrollable `lib/ui/features/settings/views/settings_screen.dart:55` `SingleChildScrollView` + `Row`, `ShareIntentService`).
- **Routing**: `lib/config/routes/app_router.dart:16` — `RoutePaths` + `rootNavigatorKey`. 4 Shell tabs + 5 full-screen outside shell (see Stack).
- **Card Generator**: 17 sealed variants (`lib/domain/models/card_data.dart:104` `SparseCard` fallback) with 16 canvases dispatched via `CardCanvasDispatcher` `lib/ui/features/card_generator/widgets/renderers/card_canvas_dispatcher.dart:33` (`CardConfig` `lib/domain/models/card_config.dart:36` from `headlineScale/scrimOpacity/palette`). Legacy `CardCanvas` `lib/ui/features/card_generator/widgets/card_canvas.dart:110` 4-case now bypassed. Schema 16 via `CardPromptManager` `lib/domain/services/card_prompt_manager.dart:47` + template-aware parsing `CardDataExtractor:24` (`template?, isRefresh`) forwarding to `IContentCurator.extractCardData(template)` `lib/data/services/curators/gemini_curator.dart:147`.
- **AI Curators**: `IContentCurator` (`lib/domain/services/content_curator.dart:25` `extractCardData(template?, isRefresh?)`) implemented by `GeminiCurator` + `OpenAICompatibleCurator` using pooled `ApiClient.dio` + `JsonCleaner.decodeIsolate` + `GenerationPromptManager`/`CardPromptManager`. `RateLimitDialog` `lib/ui/core/dialogs/rate_limit_dialog.dart:3` `suggestedFallbackProvider/currentProviderName/onRetryWithFallback` + `barrierDismissible:false` triggered from `GenerateScreen` `lib/ui/features/generate/views/generate_screen.dart:118` `ref.listen rateLimited` with `AiProvider.nextFallback:21` chain `gemini→groq→openRouter→cerebras`; inline `ErrorState:693` fallback when no model.
- **Vision Extraction**: **Excluded** per v2 verdict — `IVisionExtractor` → `MLKitVisionExtractor` `lib/data/services/ml_kit_vision_extractor.dart:1` stubbed `return ''` (no `google_mlkit_text_recognition`), probe moved `tool/dev/scrape_probe.dart`. `FootballOcrParser` `lib/domain/services/football_ocr_parser.dart:1` retained for `formatForPrompt`.
- **Secrets**: `PreferencesService` (`lib/data/services/preferences_service.dart`) stores API keys in `flutter_secure_storage` + prefs in `shared_preferences`. Never log keys.
- **Design System**: Threads tokens `lib/config/theme/app_spacing.dart:4` (`radiusMd 12/Lg 16/Pill 999`) + `AppColors` `0095F6` `lib/config/theme/app_colors.dart:13` + `AppTheme` 8 palettes `lib/config/theme/app_theme.dart:8` + `SettingsTile` `borderRadiusSm` `lib/ui/core/widgets/settings_tile.dart:35` + `chevron_right_rounded:71`.

## Testing & CI
- **Automated CI**: `.github/workflows/ci.yaml:20` pinned `3.47.1 stable` → `flutter pub get` → `dart format --output=none --set-exit-if-changed .` → `flutter analyze` (0) → `flutter test --coverage` → `dart run build_runner build` on `push: [main,master]` + `pull_request: [main,master]`.
- **Mocking**: `FlutterSecureStorage.setMockInitialValues({})` + `SharedPreferences.setMockInitialValues({})` + `ProviderScope` overrides `test/helpers/test_helpers.dart:48` (updated from deleted `app_providers.dart` → `injection.dart`).
- **Test Suites**: 82 tests spanning `test/unit/` (Curators, Renderers 17, UsageService capped 50, LogService ring 200 + 500ms persist, Interceptors `429→RateLimitFailure`, JsonCleaner, CardDataExtractor) and `test/widget_test.dart:28` 3 widget tests (4-tab nav).

## Docs
- `docs/architecture.md` — layers/DI/Network/Result (active)
- `docs/design-system-threads.md` — tokens, 9 themes, horizontal scroll
- `docs/migration-threads-convergence.md` — Kotlin Socurate → Flutter map
- `docs/baseline-phaseC.md` — Phase C baseline (vision excluded, Notifier, side-channel, 10 ImagePos) — supersedes `docs/baseline-phaseB.md`
- `CHANGELOG.md` + `CONTRIBUTING.md` — release & workflow
