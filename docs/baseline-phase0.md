# Oreamnos — Phase 0 Baseline (2026-08-25)

## Environment
- Flutter 3.47.1 stable (Dart 3.13.1) — `flutter --version` verified
- `pubspec.yaml` baseline before Phase 0.2: `flutter_lints 6.0.0`, `go_router 14.8.1`, `http 1.4.0`
- Phase 0.2 added (verified via `flutter pub get` + `dart run build_runner build`): `flutter_riverpod 2.6.1`, `riverpod_annotation 2.6.1`, `dio 5.11.0`, `freezed_annotation 3.1.0`, dev `freezed 4.0.0`, `mocktail 1.0.4`, `fake_async 1.3.3` → final toolchain: `analyzer 13.3.0`, `build 4.0.10`, `build_runner 2.16.0`, `json_serializable 6.14.1`, `source_gen 4.2.4`, `dart_style 3.1.12`
  - Note: `riverpod_generator` deferred — compatible generator line (`^2.6.5`) requires `freezed_annotation 3.x` but conflicts with `json_annotation 4.12` + `json_serializable` solver; decision: manual Riverpod providers (no codegen) for Phase A to keep Dart 3.13 toolchain clean. Revisit generator in Phase B if needed.
  - Verified `dart run build_runner build` succeeds (wrote 0 outputs, 56s) on Dart 3.13.1 — confirms toolchain coherence for upcoming sealed CardData codegen.

## Verification (pre-migration, before Riverpod rewrite)
- `flutter analyze`: 11 issues (all `info`): 2 `prefer_conditional_assignment` in `lib/data/services/web_scraper_service.dart:49,54`, 9 `avoid_print` in `test/generate_icon_test.dart:52`, `test_isurl.dart:4`, `test_scraper.dart:6,15,20,21,23,25,28`. No errors/warnings.
- `flutter test`: 8 passed (3 widget + 3 generate_view_model + 1 icon + 1 scraper implicit)
  - `test/widget_test.dart`: App renders with 3-tab nav, switches to Settings/Usage
  - `test/generate_view_model_test.dart`: `WebScraperService.isUrl`, validation, recentInputs
  - `test/generate_icon_test.dart`: generates `icon/icon.png`
- `dart run build_runner build --delete-conflicting-outputs`: not yet required (no `.freezed.dart` committed); Phase 0.2 verified via `flutter pub get` only.

## Intent for Phase 0
- Record baseline (this file)
- Add test helpers `test/helpers/` with Riverpod `ProviderScope` overrides + `FlutterSecureStorage`/`SharedPreferences` mocks (reuses `test/widget_test.dart:16` pattern)
- Add CI `.github/workflows/ci.yaml` (`flutter analyze && flutter test`)
- Extract `LogService` interface for Riverpod injection (remove singleton `LogService:19`)
- Verify `flutter analyze && flutter test` still green after Phase 0
