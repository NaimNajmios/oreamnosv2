# Changelog — Oreamnos

## v2 — Threads Convergence (2026-08-26)

* **Design system:** `Wrap` `settings_screen.dart:55` → `SingleChildScrollView` horizontal `Row` (9 modes `lib/domain/models/app_theme_mode.dart:2` `light/dark/deepBlue/midnightNoir/solarizedLight/cyberpunk/matchday/forest/system`); `SettingsTile` `brutalist→Threads` `BorderRadius.zero→borderRadiusSm` + `arrow_forward→chevron_right_rounded` `lib/ui/core/widgets/settings_tile.dart:35`; FAB `elevation 2→1` `hashtag_manager_screen.dart:186`.
* **Card engine:** `CardCanvas` 4-case `card_canvas.dart:110` → `CardCanvasDispatcher` 17 `renderers/card_canvas_dispatcher.dart:33` + `CardConfig` `lib/domain/models/card_config.dart:36`; `CardGeneratorViewModel:184` retains `polished` `CardData` 17 (`lib/domain/models/card_data.dart:104`); `CardDataExtractor:24` `template?, isRefresh` → `IContentCurator.extractCardData(template)` `lib/domain/services/content_curator.dart:25` + `CardPromptManager` 16 schemas `card_prompt_manager.dart:47`.
* **Rate limit:** `RateLimitDialog` `suggestedFallbackProvider/currentProviderName/onRetryWithFallback` + `barrierDismissible:false` `lib/ui/core/dialogs/rate_limit_dialog.dart:3`; `GenerateScreen` `ref.listen rateLimited` `lib/ui/features/generate/views/generate_screen.dart:118` with `AiProvider.nextFallback:21` chain; inline `ErrorState:693` fallback when no model.
* **Network:** `WebScraperService` `http.get 8s` + `ProviderApiService` `http` + `curators rewriteField ?key=` leak `gemini_curator.dart:214` → `@lazySingleton` dio via pooled `ApiClient` 4 interceptors `api_client.dart:23` (`Auth extra apiKey/provider`, `ErrorMapping 429→RateLimitFailure`, `Retry 4×500→60s`, `Logging`); `ProviderApiService:17` + `WebScraperService:10` via `injection.config.dart:57`.
* **Build:** `dart format` 0 changed (was 134/150), `flutter analyze` 0 (was 14), `flutter test --coverage` 75, `build_runner` 0 on 2nd run. Docs: `docs/architecture.md`, `docs/design-system-threads.md`, `docs/migration-threads-convergence.md`, `docs/baseline-phaseB.md`.

## v1 — Initial Flutter (pre-2026-08-25)

* Baseline `docs/baseline-phase0.md` — 11 info issues, 8 tests, `riverpod_generator` deferred.
