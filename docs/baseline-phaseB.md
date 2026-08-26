# Oreamnos — Phase B Baseline (2026-08-26)

> Threads Convergence + Dormant Engine Activation — post `docs/architecture.md` / `docs/design-system-threads.md` / `docs/migration-threads-convergence.md`.

## Environment

* Flutter 3.47.1 stable · Dart 3.13.1 · `flutter --version` verified `lib/main.dart:26` `ProviderScope` + `configureDependencies()`.
* Stack `pubspec.yaml:24` `dio 5.11.0`, `flutter_riverpod 2.6.1` / `riverpod 2.6.1`, `freezed 4.0.0` / `freezed_annotation 3.1.0`, `get_it 9.2.1` / `injectable 3.0.0`, `go_router 14.8.1`, `google_mlkit_text_recognition 0.17.1`, `gal 2.3.3` etc.
* `http 1.4.0` still in `pubspec` but no longer used by `WebScraperService` / `ProviderApiService` (now `ApiClient` dio) — remaining `test_scraper.dart` probe only.
* Codegen `analyzer 13.3.0` / `build 4.0.10` / `build_runner 2.16.0` / `json_serializable 6.14.1` — `dart run build_runner build --delete-conflicting-outputs` wrote 0 on 2nd run (1st wrote 4: `injection.config.dart:57`).

## Verification (post-Threads Convergence)

* `dart format --output=none --set-exit-if-changed .` → `0 changed` (was 134/150 before Phase A).
* `flutter analyze` → `No issues found!` (was 14: `invalid_annotation_target` `lib/data/services/usage_service.dart:7` etc., then 7 `curly_braces`, now 0).
* `flutter test` → `75 passed` (13 unit files + `test/widget_test.dart` 3 + `generate_view_model_test.dart` 4).
  * `test/unit/renderers_test.dart:8` 17 via `CardCanvasDispatcher` (16 + `SparseCard`).
  * `test/unit/card_data_test.dart:52`, `interceptors_test:6`, `json_cleaner:5`, `usage_service:5`, `log_service:4` etc.
* `dart run build_runner build` → `0 outputs` on 2nd run, `injection.config.dart:42` `ApiClient` before `ProviderApiService`/`WebScraperService`.

## What Phased B Shipped (vs Phase 0 `docs/baseline-phase0.md`)

| Area | Phase 0 | Phase B |
|---|---|---|
| Theme picker | `Wrap` 2 rows `settings_screen.dart:55` | `SingleChildScrollView` horizontal `Row` `lib/ui/features/settings/views/settings_screen.dart:55` (9 modes `lib/domain/models/app_theme_mode.dart:2`) |
| Card rendering | `CardCanvas` 4 cases `card_canvas.dart:110` | `CardCanvasDispatcher` 17 `lib/ui/features/card_generator/widgets/renderers/card_canvas_dispatcher.dart:33` + `CardConfig` `lib/domain/models/card_config.dart:36` |
| Card data | `CardDataExtractor:26` sparse + `CardGeneratorViewModel:194 fromBrief` discarding | `IContentCurator.extractCardData(template?,isRefresh?)` `content_curator.dart:25` → `CardPromptManager.buildPrompt` 16 schemas + `CardDataExtractor:24` forwards `effectiveTemplate` + VM `cardData=polished` `card_generator_view_model.dart:184` |
| Network | `WebScraperService http.get 8s` + `ProviderApiService http` + `rewriteField ?key=` leak | `@lazySingleton` dio via `ApiClient` pooled 4 interceptors `api_client.dart:23`, `extra:{apiKey,provider}` + `AuthInterceptor:11` |
| Rate limit | `RateLimitDialog const Got it` dead | `suggestedFallbackProvider/currentProviderName/onRetryWithFallback` + `barrierDismissible:false` + inline `ErrorState` fallback `generate_screen.dart:693` + `AiProvider.nextFallback:21` chain |
| Settings polish | `SettingsTile brutalist BorderRadius.zero + arrow_forward` + FAB `elevation 2` | `Threads borderRadiusSm + chevron_right_rounded` `settings_tile.dart:35` + FAB `1` |

## Known Debt (next)

* `Result<T>` `lib/core/error/failures.dart:3` defined, 0 call-sites (curators still `throw Exception`).
* Repos `lib/core/repositories/*` 4 defs, 0 imports, not in `injection.config.dart`.
* Hybrid `ChangeNotifierProvider` `lib/ui/features/generate/view_models/generate_view_model.dart:34` + `getIt` (see `CONTRIBUTING`).
* `http` lingering for `tool/` probes; `FootballOcrParser` missing `lib/data/services/ml_kit_vision_extractor.dart:11`; lexicon divergence `GenerationPromptManager` vs `CardPromptManager:13`; `prompt_manager.dart:1` dead.

