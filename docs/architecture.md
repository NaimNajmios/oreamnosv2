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
│   ├── error/         failures.dart  sealed Result<T>/Failure (see § Result)
│   ├── network/       ApiClient (pooled Dio) + 4 interceptors
│   └── repositories/  IContentRepository / ICardRepository / IUsageRepository / ISettingsRepository
├── data/
│   ├── models/        AiProvider (4) — baseUrl + nextFallback chain
│   └── services/      Curators (Gemini/OpenAICompat), CardDataExtractor, WebScraperService,
│                      ProviderApiService, PreferencesService, UsageService,
│                      LogService, MLKitVisionExtractor, ExportService, etc.
├── domain/
│   ├── models/        CardData (17 Freezed), CardTemplate (16), CardConfig, CuratedPost, UsageLog, AppThemeMode (9)
│   └── services/      IContentCurator, IVisionExtractor, CardPromptManager,
│                      GenerationPromptManager, JsonCleaner, PromptManager (legacy)
└── ui/
    ├── core/          AppCard/AppButton/AppChip/AppInput + SkeletonLoader/SuccessOverlay/...
    └── features/      generate / card_generator / settings / usage / shell
```

### Boundaries

* **UI → ViewModel → Repository → Curator/ApiClient** is the intended direction. After Phase B, `GenerateViewModel` still calls `CuratorFactory.getCurator(provider)` directly `lib/ui/features/generate/view_models/generate_view_model.dart:337`; `CardGeneratorViewModel` calls `getIt<CardDataExtractor>()` `card_generator_view_model.dart:128`. Phase D will promote `IContentRepository`/`ICardRepository` via Riverpod and remove factory indirection.
* Domain owns Freezed models (`CardData 17` `lib/domain/models/card_data.dart:104` `sealed class CardData with _$CardData`) and service interfaces (`IContentCurator:1`, `IVisionExtractor`).

## Routing

`lib/config/routes/app_router.dart:16`

* `ShellRoute` tabs inside `ModernAppShell:41`: `/generate` `GenerateScreen`, `/card-generator` `CardGeneratorScreen` (requires `CardBrief`), `/usage` `UsageScreen`, `/settings` `SettingsScreen` — 4 tabs (`ModernAppShell` `lib/ui/features/shell/views/modern_app_shell.dart:52` `NavigationBar` 60dp, no pill indicator).
* Full-screen outside shell: `/reading-mode` (curatedPost), `/pill-manager`, `/hashtag-manager`, `/debug-logs`, `/sessions`.

## State & DI

* **Riverpod** `ProviderScope` `lib/main.dart:26` — `generateViewModelProvider` / `cardGeneratorViewModelProvider` / `settingsViewModelProvider` are `ChangeNotifierProvider` compat `lib/ui/features/generate/view_models/generate_view_model.dart:34` (`extends ChangeNotifier with WidgetsBindingObserver:40`) delegating services via `getIt<UsageService>:67`, `getIt<IVisionExtractor>:69`, `ref.read(settingsViewModelProvider):66`. Tests use `ProviderScope` + `getIt` mocks `test/helpers/test_helpers.dart:48`.
* **get_it + injectable** — `@lazySingleton` `ApiClient`, `CardDataExtractor`, `ExportService`, `WebScraperService`, `ProviderApiService`, `PreferencesService`, `LogService`, `UsageService` `lib/core/di/injection.config.dart:42-62`. `LogService` previously singleton `LogService:19`, now injectable via Riverpod provider `lib/data/services/log_service.dart:98`.

> Plan: Phase D migrates VMs to pure `Notifier`/`AsyncNotifier`, removes `provider: ^6.1.4` shim `pubspec.yaml:18`, enables `riverpod_lint` `analysis_options.yaml:23`.

## Network

`lib/core/network/api_client.dart:13` `@lazySingleton ApiClient`

```dart
Dio(BaseOptions(
  connectTimeout: 15s, sendTimeout: 15s, receiveTimeout: 15s,
  headers: {Content-Type: application/json},
)) // api_client.dart:16
..interceptors.addAll([
  if(kDebugMode) LoggingInterceptor(),   // [DIO] →/←/✗
  AuthInterceptor(),                     // extra apiKey/provider → ?key= or Bearer
  ErrorMappingInterceptor(),             // 429→RateLimitFailure, 401/403→AuthFailure, ≥500→NetworkFailure, extra['failure']
  RetryInterceptor(dio, maxRetries:4, base 500ms, cap 60s, multiplier 2.0, jitter ±15%, honors Retry-After),
])
```

* Curators (`GeminiCurator:14`, `OpenAICompatibleCurator:14`) inject `ApiClient` (fallback `?? ApiClient()`), call `_client.post(path, data:{system_instruction, contents, generationConfig}, options: Options(extra:{apiKey, provider}))` `lib/data/services/curators/gemini_curator.dart:56`.
* `WebScraperService:10` `@lazySingleton WebScraperService(this._client)` → `_client.get<String>(url, Options(headers User-Agent/Accept, responseType plain, receiveTimeout 8s))` `web_scraper_service.dart:41`; `ProviderApiService:18` similarly via Dio (previously `http`).
* `GenerationPromptManager:6` (feed JSON `{title, body, source}`) vs `CardPromptManager:6` (16 template schemas `lib/domain/services/card_prompt_manager.dart:47` with lexicon 34 terms `card_prompt_manager.dart:13` + `N/A` + `template_intent`).

## Error Model

`lib/core/error/failures.dart:3`

```dart
sealed class Result<T> { fold(...) } // Success<T>(value) | Error<T>(failure) }
sealed class Failure { NetworkFailure | ParseFailure | RateLimitFailure | AuthFailure | ServerFailure | UnknownFailure }
```

*Defined but currently **dead** — curators throw `Exception('Gemini API Error...')` `gemini_curator.dart:80`, ViewModels string-match `errStr.contains('429')` `generate_view_model.dart:405`. `ErrorMappingInterceptor:32` attaches `extra['failure']` but is ignored. `test/unit/interceptors_test.dart:6` asserts mapping via `Result`. Phase D will migrate to `Future<Result<CuratedPost>>`.*

## Secrets

`lib/data/services/preferences_service.dart` — API keys `flutter_secure_storage` AES-256 `encryptedSharedPreferences:true` `main.dart:42` + prefs `shared_preferences`. Never log keys.

## Testing & CI

* `test/helpers/test_helpers.dart` — `FlutterSecureStorage.setMockInitialValues({})` + `SharedPreferences.setMockInitialValues({})` + `ProviderScope` overrides.
* `test/` 75 tests: Curators, Renderers 17 `CardCanvasDispatcher`, `CardDataExtractor`, `JsonCleaner`, Interceptors, `UsageService`/`LogService` capped 50/200, `GenerateViewModel`. `test/widget_test.dart:28` 3 widget tests (4-tab nav, Settings groups, Cards tab).
* `.github/workflows/ci.yaml:20` — `3.47.1` stable → `flutter pub get` → `dart format --output=none --set-exit-if-changed .` → `flutter analyze` (0 issues) → `flutter test --coverage` → `dart run build_runner build`.

## Conventions

* `freezed` + `json_serializable` codegen `dart run build_runner build --delete-conflicting-outputs`.
* File-scoped `file_path:line` citations (this doc uses them).
* No `TODO` in app code (`grep TODO` 0 hits) — backlog lives in `docs/` + this file.
