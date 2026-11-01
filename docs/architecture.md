# Architecture — Oreamnos

> Single-package Flutter app `pubspec.yaml:1` `project_type: app` · Dart `^3.13.1` · Flutter `3.47.1` stable · `flutter_riverpod 2.6.1` + `get_it`/`injectable 3.0.0` · `dio 5.11.0`

## Entrypoints

```
lib/main.dart:20 → configureDependencies() → ProviderScope → OreamnosApp
                                      ↳ NotificationService.init()
                                      ↳ QuickSettingsService.init()
```

* `lib/main.dart:26` `runApp(const ProviderScope(child: OreamnosApp()))` — Riverpod root. DI via `lib/core/di/injection.dart:13` `getIt.init()` generated in `lib/core/di/injection.config.dart:28`.
* `lib/core/di/register_module.dart:10` provides `SharedPreferences` (async factory) + `FlutterSecureStorage(encryptedSharedPreferences:true)`.
* `lib/app.dart:17` `OreamnosApp extends ConsumerStatefulWidget` — `DynamicColorBuilder:80` (themes follow system `ColorScheme`), `ref.watch(settingsViewModelProvider)` for `themeMode`, `ShareIntentService` bottom sheet `app.dart:54`.

## Layers

```
lib/
├── config/           # Routes + theme
│   ├── routes/app_router.dart:16  RoutePaths + rootNavigatorKey + GoRouter
│   └── theme/         AppTheme/AppColors/AppSpacing/AppTypography/AppMotion
├── core/
│   ├── di/            injection.dart / injection.config.dart / register_module.dart
│   ├── error/         failures.dart  sealed Result<T>/Failure (active via IContentRepository)
│   ├── network/       ApiClient pooled Dio + 4 interceptors Auth→Retry→ErrorMapping→Logging
│   └── repositories/  IContentRepository / ICardRepository / IUsageRepository / ISettingsRepository
├── data/
│   ├── models/        AiProvider (4) — baseUrl + nextFallback chain
│   └── services/      Curators (Gemini/OpenAICompat + TokenUsageSideChannel), CardDataExtractor,
│                      WebScraperService/ProviderApiService (dio), PreferencesService, UsageService,
│                      LogService, ExportService, ColorExtractor, MLKitVisionExtractor (stub)
├── domain/
│   ├── models/        CardData 17 Freezed, CardTemplate 17, CardConfig 28 (10 ImagePos,5 ExportSize,5 Filter),
│   │                  CuratedPost, UsageLog, AppThemeMode 9, CardConfigSnapshot
│   └── services/      IContentCurator, CardPromptManager 16 schemas, GenerationPromptManager (jsonSchema strict),
│                      TokenUsageSideChannel, JsonCleaner, FootballOcrParser
└── ui/
    ├── core/          AppCard/AppButton/AppChip/AppInput + SkeletonLoader (minimal) / _WatermarkOverlay drag + SuccessOverlay 25p + RateLimitDialog
    └── features/      generate (Notifier<GenerateUiState>) / card_generator (Notifier<CardGeneratorState>, 17 renderers, Freeform drag, PicsartToolDock 6 panels) / settings / usage / shell
```

### Boundaries

* **UI → ViewModel(Notifier) → Repository(Result) → Curator/ApiClient** is the enforced direction. `GenerateViewModel` now `ref.read(contentRepositoryProvider).generateStructuredPost(..., cancelToken:).timeout(AppConstants.generationReceiveTimeout 90s)` `lib/ui/features/generate/view_models/generate_view_model.dart` → `Result.fold` typed `RateLimitFailure/AuthFailure`; `CardGeneratorViewModel` via `ref.read(cardRepositoryProvider)` `card_generator_view_model.dart:142` + `IContentRepository.rewriteField` `455`.
* Domain owns Freezed models (`CardData 17` `lib/domain/models/card_data.dart:104` `sealed class CardData`) and service interfaces (`IContentCurator:1`, `TokenUsageSideChannel`).

## Routing

`lib/config/routes/app_router.dart:16`

* `ShellRoute` tabs inside `ModernAppShell:41`: `/generate` `GenerateScreen`, `/card-generator` `CardGeneratorScreen` (requires `CardBrief`), `/usage` `UsageScreen`, `/settings` `SettingsScreen` — 4 tabs (`ModernAppShell` `lib/ui/features/shell/views/modern_app_shell.dart:52` `NavigationBar` 60dp, no pill indicator).
* Full-screen outside shell: `/reading-mode` (curatedPost), `/pill-manager`, `/hashtag-manager`, `/debug-logs`, `/sessions`.

## State & DI

* **Riverpod** `ProviderScope` `lib/main.dart:26` — `generateViewModelProvider` (`NotifierProvider<GenerateViewModel, GenerateUiState>` `lib/ui/features/generate/view_models/generate_view_model.dart:44` `extends Notifier<GenerateUiState> with WidgetsBindingObserver:49`), `cardGeneratorViewModelProvider` (`NotifierProvider<CardGeneratorViewModel, CardGeneratorState>` `lib/ui/features/card_generator/view_models/card_generator_view_model.dart:36`), `settingsViewModelProvider` (`NotifierProvider<SettingsNotifier, SettingsState>` `lib/ui/features/settings/view_models/settings_view_model.dart:11`). Services via `getIt<UsageService>` + `getIt<TokenUsageSideChannel>` + `ref.read(settingsViewModelProvider)`. Tests `ProviderScope` + `getIt` mocks `test/helpers/test_helpers.dart:48`.
* **get_it + injectable** — `@lazySingleton` `ApiClient`, `TokenUsageSideChannel`, `CardDataExtractor`, `ExportService`, `IContentRepository`/`ICardRepository`/`ISettingsRepository`/`IUsageRepository`, `WebScraperService`, `ProviderApiService`, `PreferencesService`, `LogService`, `UsageService` `lib/core/di/injection.config.dart:50`. `LogService` injectable `lib/data/services/log_service.dart:98`.

## Network

`lib/core/network/api_client.dart:13` `@lazySingleton ApiClient`

```dart
Dio(BaseOptions(
  connectTimeout: 15s, sendTimeout: 15s, receiveTimeout: 15s,
  headers: {Content-Type: application/json},
)) // api_client.dart:16
..interceptors.addAll([
  AuthInterceptor(),                     // extra apiKey/provider → ?key= or Bearer
  RetryInterceptor(dio, maxRetries:4, base 500ms, cap 60s, multiplier 2.0, jitter ±15%, honors Retry-After,
                   429 policy: ≤1 honoring retry only when Retry-After ≤ 10s, else propagate immediately
                   for ViewModel fallback; constants.dart maxRetriesOn429/retry429MaxWaitMs,
                   timeouts: receiveTimeout/sendTimeout NOT retried (aborted generation already burned
                   quota); connectionTimeout/connectionError retried (nothing processed)),
  ErrorMappingInterceptor(),             // 429→RateLimitFailure, 401/403→AuthFailure, ≥500→NetworkFailure, extra['failure']
  if(kDebugMode) LoggingInterceptor(),   // [DIO] →/←/✗ last
])
// Generation requests override the pooled 15s receive window per-request with
// AppConstants.generationReceiveTimeout (90s) — Gemini generateContent streams
// nothing until the model finishes, so 15s abandoned mid-generation attempts
// (one tap → up to 5 counted requests). Short calls (extractCardData/
// rewriteField) use shortGenerationReceiveTimeout (60s). ApiClient.post/get
// forward a top-level dio `cancelToken` (NOT an Options field in dio 5).
```

* **Resilience (2026-11)**: `GenerateViewModel` runs a **silent fallback chain** on `RateLimitFailure`/`PaymentRequiredFailure` — `gemini→groq→openRouter→cerebras` ≤4 hops via `_switchToNextHealthyProvider` (skips keyless providers) shows inline `fallbackNotice` in `EnhancedLoadingCard`; `RateLimitDialog` only on full chain exhaustion. **The hop is VOLATILE:** the caller passes `forceProvider` (`_resolveModelId` picks the hop provider's stored model or its default — never another provider's selected model), so a rate-limit burst leaves the user's persisted `selectedProvider`/`selectedModel` untouched; persistent switching lives only in the explicit `retryWithProvider` dialog path. Per-provider in-memory cooldown (`_recordCooldown`, floor 60s, from `retryDelayMs`, cap 120s) makes subsequent generations skip the cooling provider outright. Share-initiated generations auto-retry ≤2× on transient failures (`NetworkFailure`/`TimeoutException`/`TwitterExtractionException`, backoff 1.5s/3s) under a combined attempt budget `_maxAttemptsPerShare = 4` (share retries + fallback hops share the cap, `_canAttemptMore`) before surfacing one-tap retry (`test/unit/generate_view_model_share_retry_test.dart`).
* **Cancellation (2026-11)**: every generation/refine/vision attempt carries a `CancelToken` (`_newAttemptToken(sessionId)` — a new session cancels the previous token) passed through `IContentRepository` → `IContentCurator` → `ApiClient.post`. Cancel sources: supersede (new tap/share/refine), VM 90s receive window expiry, `reset()`, vision 60s timeout, `ref.onDispose`. Orphaned requests no longer burn provider quota in the background.
* **Share intent (2026-11)**: `ShareIntentService.initialize()` must NOT call `reset()` before `getInitialMedia()` — purging first destroys the fresh cold-start share (regression from the pre-init-purge). Order: `getInitialMedia` → load persisted fingerprint (`share_initial_fingerprint` SharedPreferences key, loaded via `_loadFingerprint`) → `handleSharedMedia(isInitial: true)` → `reset()`. The fingerprint (`normalizeDedupKey` — strips tracking params/casing/whitespace) suppresses Android cached-process *stale replays* on the initial path only; the 1500ms transient dedup window is unchanged; `app.dart` `_inFlightShareContent` pin (guards late stream bounces) hard-expires after 8s via `Timer`.

* **Daily Quota Visibility (2026-10)**: `DailyUsageService` `@lazySingleton` `lib/data/services/daily_usage_service.dart` persists a compact per-day counter map (`daily_usage_v1` SharedPreferences `{ "<pacificDayKey>": { "<provider>:<model>": count } }`) — day rolls over at midnight Pacific (Google's RPD reset), dependency-free US-DST helper. Every attempt (success + `429`-burned failures) is counted via `UsageService.logUsage` (single funnel, `vision` pseudo-provider excluded) since the 50-cap log history can't derive daily counts. Free-tier budget table (estimated): `2.0-flash/-lite`→1500, `2.5-flash`→500, `2.5-flash-lite`→1000, unknown→`AppConstants.defaultDailyQuota` 500; amber at `dailyQuotaWarnThreshold` 0.8, red at 100%. Usage tab card "DAILY QUOTA — GEMINI (EST.)" shows `LinearProgressIndicator` bars per model + "Resets in Xh Ym (midnight PT)" footer; device-local estimate only (real quota is per Google project, other keys included). Test `test/unit/daily_usage_service_test.dart` (`@ignoreParam`-injected `DailyUsageClock` override for rollover tests).
* Curators (`GeminiCurator:15`, `OpenAICompatibleCurator:15`) inject `ApiClient` (fallback `?? ApiClient()`), call `_client.post(path, data:{system_instruction, contents, generationConfig:{responseMimeType, responseSchema}}, options: Options(extra:{apiKey, provider}))` `lib/data/services/curators/gemini_curator.dart:62` — `GenerationPromptManager.jsonSchema` wired to Gemini `responseSchema` / OpenAI `json_schema strict`. Tokens via side-channel `TokenUsageSideChannel` `lib/data/services/token_usage_side_channel.dart:1` (`usageMetadata/total_tokens`).
* `WebScraperService:10` `@lazySingleton WebScraperService(this._client)` → `_client.get<String>(url, Options(headers User-Agent/Accept, responseType plain, receiveTimeout 8s))` `web_scraper_service.dart:41`; `ProviderApiService:18` similarly via Dio (previously `http`, probe moved `tool/dev/scrape_probe.dart`).
* `GenerationPromptManager:6` (feed JSON `{title, body, source}`) vs `CardPromptManager:6` (16 template schemas `lib/domain/services/card_prompt_manager.dart:47` with lexicon 37 terms `card_prompt_manager.dart:13` + `template_intent`).

## Error Model

`lib/core/error/failures.dart:3`

```dart
sealed class Result<T> { fold(...) } // Success<T>(value) | Error<T>(failure) }
sealed class Failure { NetworkFailure | ParseFailure | RateLimitFailure | AuthFailure | ServerFailure | UnknownFailure }
```

*Active via `IContentRepository` `lib/core/repositories/content_repository.dart:52` `Result<CuratedPost>` → `GenerateViewModel` `lib/ui/features/generate/view_models/generate_view_model.dart:382` `repoResult is ResultError → failure is RateLimitFailure` (no `contains('429')`), + `refineContent:585`. `ErrorMappingInterceptor:23` `extra['failure']` → `ContentRepository._mapError:44`. `test/unit/interceptors_test.dart:6` asserts mapping.*

## Secrets

`lib/data/services/preferences_service.dart` — API keys `flutter_secure_storage` AES-256 `encryptedSharedPreferences:true` `main.dart:42` + prefs `shared_preferences`. Never log keys.

## Testing & CI

* `test/helpers/test_helpers.dart` — `FlutterSecureStorage.setMockInitialValues({})` + `SharedPreferences.setMockInitialValues({})` + `ProviderScope` overrides.
* `test/` 293 tests across 43 files: Curators + error paths, Renderers 17 `CardCanvasDispatcher` (including `ImagePosition` 10 branch + `watermark` drag/size + `opacity/blur/badge`), `CardDataExtractor`, `JsonCleaner`, Interceptors (`429→RateLimitFailure` typed + timeout retry policy), `UsageService`/`LogService` capped 50/200, `DailyUsageService` Pacific-day budgets, `GenerateViewModel` (`Notifier<GenerateUiState>` + `contentRepositoryProvider` mock + share retry + volatile fallback), `ShareIntentService` fingerprint stale-replay, `TokenUsageSideChannel` side-channel. `test/widget_test.dart:28` 4 widget tests (4-tab nav, Settings/Cards tab).
* `.github/workflows/ci.yaml:20` — `3.47.1` stable → `flutter pub get` → `dart format --output=none --set-exit-if-changed .` → `flutter analyze` (0 issues) → `flutter test --coverage` → `dart run build_runner build` (freezed/json/injectable).

## Conventions

* `freezed` + `json_serializable` codegen `dart run build_runner build --delete-conflicting-outputs`.
* File-scoped `file_path:line` citations (this doc uses them).
* No `TODO` in app code (`grep TODO` 0 hits) — backlog lives in `docs/` + this file.
