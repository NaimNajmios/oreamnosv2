# Roadmap — Result<T> / Failure

> `lib/core/error/failures.dart:3` `sealed Result<T> { Success | Error }` + `Failure` 6 variants (`NetworkFailure:39`, `ParseFailure:43`, `RateLimitFailure:47`, `AuthFailure:51`, `ServerFailure:55`).

## Current: Dead Code

* `ErrorMappingInterceptor:33` `extra['failure']=failure` → `handler.next(err)` ignored.
* Curators `throw Exception('Gemini API Error...')` `lib/data/services/curators/gemini_curator.dart:80` → ViewModels `errStr.contains('429')` `lib/ui/features/generate/view_models/generate_view_model.dart:405` stringly-typed.
* `Result<` grep = only `failures.dart:3,21,26`; `test/unit/interceptors_test.dart:6` asserts `RateLimitFailure` but not via `fold`.

## Plan (separate doc, injectable + Riverpod)

1. `IContentCurator.generateStructuredPost` → `Future<Result<CuratedPost>>`; `CardDataExtractor.extractCardData` → `Result<CardData>`; `ProviderApiService.fetchModels` → `Result<List<String>>`.
2. `ApiClient` interceptors propagate `ResultError` via `DioException` → `ErrorMappingInterceptor:15` returns `ResultError(Failure)`.
3. ViewModels replace `try/catch e.toString()` with `res.fold(onSuccess:(post){_curatedPost=post}, onError:(failure){ failure is RateLimitFailure → _state=rateLimited + suggestedFallback = current.nextFallback })`.
4. Tests `interceptors_test` → `Result.fold` asserts.

