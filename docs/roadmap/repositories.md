# Roadmap — Repositories (Riverpod Injection)

> Status: **TODO Phase D** — `lib/core/repositories/` defined, 0 imports.

## Current

* `lib/core/repositories/content_repository.dart:5` `abstract IContentRepository` + `ContentRepository` wraps `CuratorFactory.getCurator:41` (static).
* `card_repository.dart:6`, `usage_repository.dart:4`, `settings_repository.dart:7` similar — not in `lib/core/di/injection.config.dart:28`.

*ViewModels bypass:* `generate_view_model.dart:337 CuratorFactory.getCurator`, `card_generator_view_model.dart:128 getIt<CardDataExtractor>` `lib/ui/features/generate/view_models/generate_view_model.dart:67 getIt`.

## Decision (per user: inject with Riverpod, else delete)

**Inject with Riverpod** — preferred. Alternative is `git rm lib/core/repositories/*` to kill dead code if no injection space, but user prefers injection.

## Plan (separate doc, full migration now — not incremental)

1. `@lazySingleton` `ContentRepository`/`CardRepository`/`UsageRepository`/`SettingsRepository` → `injection.config.dart:42` `gh.lazySingleton<IContentRepository>(() => ContentRepository(gh<ApiClient>(), gh<CardDataExtractor>()))`.
2. Expose `contentRepositoryProvider` / `cardRepositoryProvider` as Riverpod `Provider<IContentRepository>` wrapping `getIt`.
3. Migrate `GenerateViewModel` → `ref.read(contentRepositoryProvider).generate(...)` returning `Result<CuratedPost>` (see `result.md`); delete `CuratorFactory` static.
4. `dart run build_runner build --delete-conflicting-outputs` → 0 outputs on 2nd run; `flutter test` 75+ with repo mock overrides.

## Verification

* `grep -r "IContentRepository" lib/` >0 imports; `flutter analyze 0`; `injection.config.dart` shows 4 new `lazySingleton`.

