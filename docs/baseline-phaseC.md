# Oreamnos — Phase C Baseline (2026-08-30)

> Post vision exclusion + Notifier migration + API resilience + Card Studio depth — supersedes `docs/baseline-phaseB.md`.

## Environment
* Flutter 3.47.1 stable · Dart 3.13.1 · `flutter --version` verified `lib/main.dart:26` `ProviderScope` + `configureDependencies()` (`getIt.init`).
* Stack `pubspec.yaml:53` `dio 5.11.0`, `flutter_riverpod 2.6.1` / `riverpod 2.6.1`, `freezed 4.0.0` / `freezed_annotation 3.1.0`, `get_it 9.2.1` / `injectable 3.0.0`, `go_router 14.8.1`, `gal 2.3.3`, `image_picker 1.2.3` (vision `google_mlkit_text_recognition` removed, probe moved `tool/dev/scrape_probe.dart`).
* Codegen `analyzer 13.3.0` / `build 4.0.10` / `build_runner 2.16.0` / `json_serializable 6.14.1` — `dart run build_runner build` wrote 7 on 1st run (freezed `GenerateUiState`/`CardGeneratorState` + `TokenUsageSideChannel` injectable), 0 on 2nd.

## Verification (post Phase C)
* `dart format --output=none --set-exit-if-changed .` → `0 changed`
* `flutter analyze` → `No issues found!`
* `flutter test --coverage` → `82 passed` (17 renderers via `CardCanvasDispatcher` + `ImagePosition` 10 branch + watermark image/size/drag + `opacity/blur/badge` + token side-channel)
* `dart run build_runner build` → `7 outputs` on 1st, `0` on 2nd; `lib/core/di/injection.config.dart:50` registers `ApiClient` before `TokenUsageSideChannel`/`IContentRepository`.

## What Phase C Shipped (vs Phase B `docs/baseline-phaseB.md`)
| Area | Phase B | Phase C |
|---|---|---|
| Vision | `MLKitVisionExtractor` `google_mlkit_text_recognition 0.17.1` stub | **Excluded** — stub `return ''` + `pubspec` no `google_mlkit`, probe `tool/dev/scrape_probe.dart` |
| State | `ChangeNotifierProvider` compat `GenerateViewModel:34` | `NotifierProvider<GenerateViewModel, GenerateUiState>` `generate_state.dart:10` + `CardGeneratorViewModel:36` + `SettingsNotifier:11` pure `Notifier` |
| Network | `ApiClient` pooled `Auth→ErrorMapping→Retry→Logging` | Reordered `Auth→Retry→ErrorMapping→Logging` `api_client.dart:23` + `IContentRepository` `Result<CuratedPost>` fold `generate_view_model.dart:382` + 30s timeout + strict `jsonSchema` `GenerationPromptManager.jsonSchema` wired `gemini_curator.dart:62`/`openai_compatible_curator.dart:60` + side-channel `TokenUsageSideChannel` `gemini_curator.dart:105` |
| Export | `ExportSize` 3 `square/portrait/story` collapsed `wide/photo34→portrait` | `ExportSize` 5 `wide/photo34` `card_config.dart:23` `fromRatioName` + adaptive `pixelRatio 2.5-3.0` `card_generator_view_model.dart:513` |
| Card studio | `ImagePosition` 10 stored not rendered (`BoxFit.cover` always) | Visually branched `_buildBackgroundByPosition:313` (splitLeft/Right/overlayTop/minimal/cutout/magazineBold/offsetCard/brutalist/floatWindow) `card_generator_screen.dart:313` |
| Filters | `PhotoFilter` 5 enum only 2 matrices | 5 matrices `blackWhite/vintage/vibrant/highContrast` `card_generator_screen.dart:401` |
| Watermark | Text fixed `bottom:12 right:12 size10` | Image upload `pickWatermarkImage:284` + `watermarkImage/size 24-160/offset 0.05-0.95` drag `_WatermarkOverlay:514` + snapshot `card_config_snapshot.dart:22` + opacity/blur/badge/accent wiring `card_generator_screen.dart:318,332,382` |
| Snapshot | `undoStack` missing `headlineOffset/subtextOffset/microStatOffset` + `imagePosition/photoFilter` not restored | Added 3 offsets to `CardConfigSnapshot:43` + `card_generator_state.dart:81` + `_applySnapshot:96` restores 22 fields; `updateElementOffset` + `saveDragSnapshot()` |
| Design system | `Generate` had `Scan Image` pill, `SkeletonLoader` only | `SkeletonLoader` intentionally minimal (keep), no Scan Image, `badge/accent/blur/opacity` wired; `Tool` preset gradients `stadiumBlur/darkMesh/grassTexture` `_presetGradient:460` |

## Known Debt (next)
* `elementOffsets: Map<String,Offset>` `card_config.dart:63` pruned (separate `headlineOffset` etc are source of truth); `cutoutPath/previewScale` pruned.
* `GenerationPromptManager.containsQuotes/...isLongTechnicalContent` + `CardPromptManager._sparseSchema` unused helpers.
* `UsageService`/`LogService` still `ChangeNotifier` (not `Notifier`) — Roadmap Phase D deferred.
* Golden coverage for `ImagePosition` 10 + `watermark` drag/size + `opacity/blur/badge` pending.
