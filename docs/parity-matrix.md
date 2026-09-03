# Parity Matrix — Oreamnos v2 100% Contract (2026-09-04)

Source of truth. Sealed `CardData` 17 kept by decision (no `values`-map rebuild).

## v3 — Full Original Parity Pass (2026-09-04, 148 tests green)

| Scope item | Status | Evidence |
|---|---|---|
| Correctness fixes | ✅ | `getMatchColors` home.first+away.second, exact club hex + named presets (`color_extractor.dart`), 4-stop scrim math (`gradient_builder.dart`), standings 5-row cap (`card_data_extractor.dart`), `CustomPill.id` stable (`custom_pill.dart`) |
| Rate-limit metadata | ✅ | `RateLimitFailure(retryDelayMs, providerName, waitTimeMessage)` (`failures.dart`), Gemini `details.retryDelay` + `Retry-After` parse (`error_interceptor.dart`), dialog wait chip + VM message (`rate_limit_dialog.dart`, `generate_view_model.dart`). Policy kept: retry-then-dialog |
| Provider robustness | ✅ | OpenRouter headers + `max_tokens:2048` + 30/60s timeouts (`openai_compatible_curator.dart`), offline `defaultModelId` per provider (`ai_provider.dart`), Test Connection tile (`test_connection_tile.dart`) |
| Prompt parity | ✅ | Length multipliers 20-30/40-60/70-90 + floors (`lengthRange`), technical branch, bullet rules, FORBIDDEN block, `containsQuotes`/`isLongTechnicalContent` + 26 keywords, `buildRefinementPrompt`, `buildPromptFromOcr` (`generation_prompt_manager.dart`); length threaded repo→curators→prompts |
| Full refine pipeline | ✅ | `IContentCurator.refinePost` + both curators + `ContentRepository.refinePost`; VM `refineContent` routes single/custom pills through `buildRefinementPrompt` |
| ResponseCleanup | ✅ | `response_cleanup.dart` full port (citation/bullets/phrases/whitespace/<50 guard/asterisks), wired into both curators' markdown fallback |
| Scraper parity | ✅ | Unwanted-element strip, promo patterns, newline-run collapse, bare/`www.` `isUrl` + `normalizeUrl` (`web_scraper_service.dart`) |
| Card Studio depth | ✅ | `shuffleDesign` undoable (`card_generator_view_model.dart`), `TemplatePickerGrid` 2-col previews + check (`template_picker_grid.dart`, dock panel), Deck list editors + bool switches (`studio_deck_lists.dart`, `updateCardListField`/`setCardBoolField`), Oreamnos gallery album (`export_service.dart`), public `DraggableCanvasElement` (freeform; structured canvases stay flow-layout by design) |
| Generate UX | ✅ | Edit mode (`isEditMode`, `FluidEditButton`, `_PostEditor`), output typewriter confirmed live via `BodyBlock`, `LinkPreviewCard` dismiss + lazily fetched title/desc/favicon, QS-tile clipboard pickup, `card:` share routing to Card Studio |
| Usage analytics | ✅ | `SuccessRateDonut`, `ResponseTimeBars` (avg/min/max + badges), 7/30/90d range filter, `getAverageResponseTime…/getFastest…/getSlowest…` (`usage_service.dart`). Prompt/response token split deferred (needs `UsageLog` schema migration) |
| Motion parity | ✅ | Checkmark circle arc + overshoot (`particles_painter.dart`), `AppChip` press-scale + long-press + select check |
| Tests | ✅ | 155 total: `parity_utils_test` (readability/detectors/cleanup/scraper), `usage_stats_parity_test`, curator 429, prefs, deck, VM shuffle/lists/bools, edit mode, Gemini schema strip, 400 mapping/truncation, dialog overflow |
| Gemini structured output | ✅ | `geminiResponseSchema` (stripped variant) sent at both Gemini schema call sites; OpenAI keeps strict `jsonSchema`; schema-less retry on 400 naming `response_schema` |
| Error UX | ✅ | Friendly 400/401 messages, 220-char body cap, scrollable `ErrorState` (no dialog overflow) |
| Still excluded (v2 verdict) | ➖ | On-device vision models, HF download, AICore, `PROCESS_TEXT`, bg `ContentGenerationService`, exact-px offscreen export (PNG@3x ≈1080px+ deemed equivalent), markdown benchmarks |

| Scope item | Status | Evidence |
|---|---|---|
| 16 card templates + typed extraction + freeform | ✅ | `card_data.dart:104` 17 variants, `card_template.dart:3` 17, `card_field_registry.dart:9` 17 branches, `card_prompt_manager.dart:36` per-template + caps, `card_canvas_dispatcher.dart:35` 17-way |
| Retry/backoff + rate-limit fallback dialog | ✅ | `api_client.dart:24-35` 4 interceptors, `constants.dart:19-22` 4×500ms→60s, `retry_interceptor.dart:62-67,95-102`, `error_interceptor.dart:15` 429→RateLimitFailure, `rate_limit_dialog.dart:4` + `generate_screen.dart:138-152` + `ai_provider.dart:21` chain |
| Full PromptManager + ResponseCleanup | ✅* | 37 terms `football_lexicon.dart:6-44` via `generation_prompt_manager.dart:47-50`, `football_ocr_parser.dart:9` formatForPrompt; `ResponseCleanup.kt` superseded by `JsonCleaner:5-35` + strict `jsonSchema` + markdown fallback — documented, not ported |
| 8 themes (9 modes), 4-tab nav, loading/success polish | ✅ | 9 modes `app_theme_mode.dart:2-11`, 4-tab `app_router.dart:48-126`, `EnhancedLoadingCard` wired `generate_screen.dart:_buildResultArea`, skeleton/stagger/success-25p/two-step-clear/link-preview done |
| Studio deck (editable fields), undo/redo | ✅ | `studio_deck_sheet.dart` (this release) on `CardFieldRegistry.fieldsFor` + `missingFields` + `rewriteDynamicField`; undo/redo 50 `card_generator_view_model.dart:43,65-95` + UI `:435-455` |
| Export sizes ×3+, image positions, filters, watermark | ✅ | 5 sizes / 10 positions / 5 filters `card_config.dart:8-28`, watermark/font/shadow/glow/blur/badge/palette `:60-70,92-100,132-140` |
| Real token accounting from API metadata | ✅ | `token_usage_side_channel.dart:7-43` (`usageMetadata`/`usage`), `generate_view_model.dart:469-478` real-over-estimate, `usage_service.dart:37-39` cap 50 |
| Test suite + release artifacts | ✅* | 100+ tests / 22 files + new prefs/curator-429/deck tests; CI `3.47.1`; ProGuard hardened; `key.properties`/`*.jks` gitignored (rotate secret); goldens: smoke via `renderers_test.dart` (full alchemist goldens deferred) |
| Out of scope (dropped) | ➖ | LiteRT Gemma/PaliGemma/Nano, HF download, AICore, PROCESS_TEXT, `MLKitVisionExtractor` stubbed `ml_kit_vision_extractor.dart:1` |
