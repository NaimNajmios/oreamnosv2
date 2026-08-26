# Migration — Threads Convergence (Kotlin Socurate → Flutter Oreamnos)

> Consolidates `project_context/naimnajmios-socurate-…` Kotlin dump + `project_context/migration_plan` Phases 0-9.
> All paths absolute `C:\Users\NAIM\Documents\Personal\Flutter\oreamnos`.

## Stack Map

| Android (Kotlin) | Flutter (Dart) | File |
|---|---|---|
| Jetpack Compose + BOM 2024.02 + Material3 | Flutter 3.47.1 + `useMaterial3` `lib/config/theme/app_theme.dart:191` + `DynamicColorBuilder` `lib/app.dart:80` |  |
| OkHttp 4.12 + Gson 2.10 | `dio 5.11.0` pooled `ApiClient` `lib/core/network/api_client.dart:13` + `freezed`/`json_serializable` `lib/domain/models/card_data.dart:5` |  |
| ViewModel + LiveData + Hilt | `flutter_riverpod 2.6.1` `ProviderScope` `lib/main.dart:26` + `get_it`/`injectable` `lib/core/di/injection.config.dart:28` |  |
| `GeminiService.java:840` retry `Queued` | `RetryInterceptor:11` `QueuedInterceptor` 4× `base 500 cap 60s mult 2.0 jitter ±15%` + `Retry-After` `lib/core/network/interceptors/retry_interceptor.dart:91` |  |
| `RateLimitException` + `showRateLimitDialog` | `ErrorMappingInterceptor:15` `429→RateLimitFailure` `lib/core/error/failures.dart:47` + `GenerateViewModel.suggestedFallbackProvider:124` `nextFallback:21` + `RateLimitDialog:3` modal + inline `ErrorState:693` |  |
| `CardData sealed 16` `CardData.kt` | `CardData sealed 17` (16 + `SparseCard`) `lib/domain/models/card_data.dart:104` `freezed` + `CardTemplate 16` `lib/domain/models/card_template.dart:3` |  |
| `CardPromptManager.kt` 16 schemas + `CRITICAL RULE 3 N/A` | `CardPromptManager:6` `CRITICAL RULE 3 N/A:14` + 16 `_schemaFor` `card_prompt_manager.dart:47` |  |
| `FootballOcrParser.formatForPrompt` `22471` | **TODO** — `MLKitVisionExtractor:11` currently `recognizedText.text` passthrough `lib/data/services/ml_kit_vision_extractor.dart:11` |  |
| `Brutalist/Neo-Editorial` sharp `0dp` + `FF4500` | `Threads` rounded `radiusMd 12/Lg 16/Pill 999` `lib/config/theme/app_spacing.dart:21` + `0095F6` `lib/config/theme/app_colors.dart:13` |  |

## Threads Convergence (Phase B) — What Changed

| Area | Before | After | Code |
|---|---|---|---|
| Theme picker | `Wrap` 2 rows ~144px `settings_screen.dart:55` | `SingleChildScrollView` horizontal + `Row` single row ~66px | `settings_screen.dart:55` |
| Card rendering | `CardCanvas` 4 cases `card_canvas.dart:110` collapsing 12 templates to black `141416` | `CardCanvasDispatcher` 17 `cardData.map` `renderers/card_canvas_dispatcher.dart:33` + `CardConfig` `lib/domain/models/card_config.dart:36` built from `headlineScale/scrimOpacity/vignette/palette` | `card_generator_screen.dart:289` |
| Card data | `extractor:26` sparse `CuratorFactory.getCurator` + `CardGeneratorViewModel:194 fromBrief` discarding | `IContentCurator.extractCardData(template?, isRefresh?)` `content_curator.dart:25` → `CardPromptManager.buildPrompt(template, brief.promptContext)` `curators/gemini_curator.dart:147` + extractor forwards `effectiveTemplate/isRefresh` `card_data_extractor.dart:24` + VM retains `polished` `card_generator_view_model.dart:184` |  |
| Rate limit | `RateLimitDialog const` single `Got it` `dialogs/rate_limit_dialog.dart:4` dead `grep 0` | `suggestedFallbackProvider/currentProviderName/onRetryWithFallback` + `barrierDismissible:false` + `FilledButton Retry with X` + `GenerateScreen` `ref.listen` `rateLimited` → dialog `lib/ui/features/generate/views/generate_screen.dart:118` + fallback inline `ErrorState` |  |
| Network | `WebScraperService http.get 8s` `web_scraper_service.dart:23` + `ProviderApiService http 1.4.0` `provider_api_service.dart:3` + `curators rewriteField ?key=` leak `gemini_curator.dart:214` | `@lazySingleton` dio `WebScraperService(this._client)` `get<String>(url, Options(headers User-Agent, responseType plain, receiveTimeout 8s))` + `ProviderApiService(this._client)` `get(v1beta/models?key)` / `get($baseUrl/models)` via `extra:{apiKey, provider}` + `AuthInterceptor:11` |  |
| Settings polish | `SettingsTile brutalist + BorderRadius.zero:35 + arrow_forward` | `Threads + borderRadiusSm:35 + chevron_right_rounded:71` + FAB `elevation 1` `hashtag_manager_screen.dart:186` |  |

## Remaining for Separate Docs (per user: not one roadmap)

* **Architecture debt:** `Result<T>` dead `lib/core/error/failures.dart:3` + repos `lib/core/repositories/content_repository.dart:5` bypassed `generate_view_model.dart:337` + `ChangeNotifier` hybrid `lib/ui/features/generate/view_models/generate_view_model.dart:34` — see `docs/roadmap/next.md` (to be created) as separate docs per area.
* **Prompt lexicon:** `GenerationPromptManager:11` missing 34 football terms `card_prompt_manager.dart:13` + `FootballOcrParser` → separate `docs/roadmap/prompt.md`.
* See `docs/architecture.md` + `docs/design-system-threads.md` for living specs.
