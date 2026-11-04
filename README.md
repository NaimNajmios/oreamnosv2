# Oreamnos

**Oreamnos** is an AI-assisted editorial curator and social card generator built with Flutter. It streamlines the workflow of curating, polishing, and designing sports media content (specifically football/soccer) across multiple LLM providers (**Gemini**, **Groq**, **OpenRouter**, **Cerebras**) with rich Malay editorial styling, strict JSON extraction, and instant shareable canvas generation. **On-device vision/ML Kit is intentionally excluded (v2 verdict — stubbed `MLKitVisionExtractor`).**

---

## Key Features

### 1. Multi-Provider AI Content Generation (Resilient)
- **Supported Providers**: Google Gemini, Groq, OpenRouter, Cerebras (`AiProvider.nextFallback:21` chain `gemini→groq→openRouter→cerebras`).
- **Dynamic Model Discovery**: Fetches compatible models on the fly per API key (`ProviderApiService` via pooled `ApiClient.dio`).
- **Resilient Network Layer**: `ApiClient` `lib/core/network/api_client.dart:13` pooled Dio `15s` + 4 interceptors ordered `Auth→Retry(4×500ms→60s jitter, Retry-After)→ErrorMapping(429→RateLimitFailure)→Logging` + `IContentRepository` `lib/core/repositories/content_repository.dart:52` `Result<CuratedPost>` fold (no `contains('429')` strings) + 30s timeout `lib/ui/features/generate/view_models/generate_view_model.dart:370` + strict `json_schema` `GenerationPromptManager.jsonSchema` wired to `responseSchema`/`response_format`.
- **Rate-Limit Recovery**: `RateLimitFailure(retryDelayMs/providerName/waitTimeMessage)` parses Gemini `details.retryDelay` + `Retry-After`; `RateLimitDialog` shows the wait chip with `AiProvider.nextFallback` switch-and-retry (policy: retry-then-dialog).
- **Provider Robustness**: offline `defaultModelId` per provider (generation falls back instead of erroring), Test Connection tile in Settings, OpenRouter ranking headers, `max_tokens:2048`, 30/60s OpenAI-path timeouts.
- **Full Refinement Pipeline**: `IContentCurator.refinePost` (rephrase / recheck_flow / recheck_wording keys + free-text custom pills via `GenerationPromptManager.buildRefinementPrompt`) in both curators, wrapped by `ContentRepository.refinePost`; output **edit mode** (`FluidEditButton` + inline editor, undoable).
- **Prompt Parity**: length multipliers (short 20-30 / medium 40-60 / long 70-90%), technical-analysis branch, bullet/quote detectors, FORBIDDEN block; `ResponseCleanup` port applied to markdown fallbacks.
- **Title formatting**: the output chips include **Uppercase** next to **Title**. The title renders with wider tracking and flows into copy/share/reading mode/Facebook drafts; the body, hashtags and source keep their case. The toggle persists with generation options.
- **Token Side-Channel**: `TokenUsageSideChannel` `lib/data/services/token_usage_side_channel.dart:1` captures `usageMetadata.totalTokenCount` (Gemini) / `usage.total_tokens` (OpenAI) per response; `GenerateViewModel` consumes real tokens with heuristic fallback.
- **Background Isolate Parsing**: `JsonCleaner.decodeIsolate` `lib/domain/services/json_cleaner.dart:5`.

### 2. Multi-Variant Card Generator (16 Templates + Sparse Fallback → 17 Renderers, 10 Image Positions, 5 Export Ratios)
Instant, pixel-perfect graphics with deterministic JSON schema extraction and customized canvas renderers (`CardCanvasDispatcher` `lib/ui/features/card_generator/widgets/renderers/card_canvas_dispatcher.dart:33` dispatches 17: 16 + `SparseCard`):
- **Templates (16→17)**: Player Spotlight, Headline Quote, Top Stats, Transfer News, Breaking News, Match Preview, Detailed Scoreboard, On This Day, Starting XI, Match Stats Comparison, Social Post, Rivalry, Table Standings, Injury Report, Contract Expiry, Award Nominee, Sparse.
- **Design Studio (Picsart dock) `lib/ui/features/card_generator/widgets/picsart_tool_dock.dart:18` 6 panels** `templates/ratio/background/typography/text/branding`:
  - **Ratios 5** `CardRatio` `lib/ui/features/card_generator/view_models/card_generator_view_model.dart:21` `square(1:1)/portrait45(4:5)/story(9:16)/wide(16:9)/photo34(3:4)` → `ExportSize` `lib/domain/models/card_config.dart:23` `square 1080×1080 ... photo34 1080×1440` via `fromRatioName` + adaptive `pixelRatio 2.5-3.0` `card_generator_view_model.dart:513`.
  - **Image Positions 10** `ImagePosition` `lib/domain/models/card_config.dart:8` `background/splitLeft/splitRight/overlayTop/cutout/minimal/magazineBold/offsetCard/brutalist/floatWindow` visually branched `lib/ui/features/card_generator/views/card_generator_screen.dart:306` (`_buildBackgroundByPosition`).
  - **Palette**: auto-extraction `ColorExtractor` 200px Thumb + manual solids + `accentColor` `card_config.dart:62`.
  - **Typography**: `Inter/Lora/Space Mono` `card_generator_screen.dart:333` + `headlineScale 0.85-1.15` + `textShadowRadius/color` + `isGlowEnabled` (`Offset.zero` glow vs `2,2`) `card_config.dart:137`.
  - **Filters 5** `PhotoFilter` `card_config.dart:21` `none/blackWhite/vintage/vibrant(1.4 sat)/highContrast(1.5)` matrix `card_generator_screen.dart:401`.
  - **Overlays**: `imageOpacity 0.2-1.0` `Opacity` + `backgroundBlur 0-25` `ImageFiltered` `_wrapWithOpacityAndBlur:442`, `badgeText` pill `top:12 left:12 accentColor`, scrim `dark/minimal` + `overlayOpacity 0.3-0.75`.
- **Watermark (image + text, draggable, undoable)**: `watermarkImage` `image_picker:90` `pickWatermarkImage:284` + `watermarkSize 24-160` slider `picsart_tool_dock.dart:660` + `watermarkOffset 0.05-0.95` drag `_WatermarkOverlay:514` `GestureDetector onPanUpdate` + snapshot `watermarkImage/size/offset` `card_config_snapshot.dart:22` `card_generator_state.dart:66` (`toSnapshot:81`/`_applySnapshot:96`).
- **Freeform drag**: `headlineOffset/subtextOffset/microStatOffset` `card_generator_state.dart:66` draggable `FreeformCanvas:46` via reusable `DraggableCanvasElement` with `saveDragSnapshot()` `card_generator_view_model.dart:373` + snapshot restore. (Structured canvases stay flow-layout by design.)
- **Studio Deck sheet** `lib/ui/features/card_generator/widgets/studio_deck_sheet.dart:20`: registry-driven field editor (char counters, MISSING amber chips, blank-required detection), per-field AI polish, AI Rewrite All, template switcher with cached re-extraction, **list editors** for lineups/stats/standings/injuries/nominees (`studio_deck_lists.dart`, caps 11/7/5, number coercion) + bool switches — all undoable via `updateCardListField`/`setCardBoolField`.
- **TemplatePickerGrid**: 2-column mini gradient previews + selected check badge in the dock templates panel, plus undoable **Surprise-Me `shuffleDesign`**.
- **Exact club colors + scrims**: Android-faithful `ColorExtractor` hex map + named presets (JDT/Selangor/Pahang/Kedah/Perak/Malaysia), `getMatchColors` home-start + away-end, 4-stop scrim math in `GradientBuilder`.
- **High-Res Export**: `RepaintBoundary` `_boundaryKey` → `ExportService.capturePng(pixelRatio ≈1080px+)` → `Gal.putImage` into the **Oreamnos album** / `SharePlus` `card_generator_view_model.dart:513` (lossless PNG preferred over JPEG for flat graphics/text).

> Pruned (not implemented): `cutoutBitmap`, `CardConfig.elementOffsets` map (shadowed by separate freeform offsets + watermark drag) — badge/accent/blur/opacity only, per original.

### 3. Vision Extraction — Excluded (v2 Verdict)
- **On-device vision models excluded**: `Gemma 3n/1B/PaliGemma/Nano/LiteRTEngine/VisionModelManager` intentionally not ported (≈15% original complexity). `MLKitVisionExtractor` `lib/data/services/ml_kit_vision_extractor.dart:1` stubbed (returns `''`), `google_mlkit_text_recognition` removed from `pubspec.yaml` (probe moved `tool/scrape_probe.dart → tool/dev/scrape_probe.dart`).
- **Image picker retained** for card backgrounds `lib/ui/features/card_generator/view_models/card_generator_view_model.dart:489` + watermark logos `284` (background/watermark `image_picker:90` only) — no OCR path on Generate.

### 4. Facebook Page Publishing (Graph API)
- **Dedicated Publish tab**: publishing has its own bottom-nav home (`/publish`) with Page identity/switcher, a **Create a post** CTA, draft/scheduled/published counts, the next scheduled post, a continue-writing card, recent posts with insights/Story status, and shortcuts to Drafts, Published, Workflows and Storage. Settings no longer hosts Facebook tiles; composer/history/drafts/workflows/comments open as full-screen pushes from the hub.
- **Connect once, post to any Page**: paste a **user token** (recommended, `pages_show_list` + `pages_read_engagement` + `pages_manage_posts`) and every Page is discovered via `GET /me/accounts`; only the derived Page tokens are persisted, each under `facebook_page_token_<pageId>`. The user token is exchanged and discarded — never written to prefs, secure storage, drafts, logs or analytics. A Page-token path remains for single-Page setups. `FacebookPageService` owns verification + exchange.
- **Page switcher + draft safety**: `PageSwitcherSheet` changes the active publish target from the composer header. Each draft is stamped with its Page; switching Pages with a non-empty draft opens a **Switch target / Duplicate draft / Keep original Page** guard so a caption cannot silently post to the wrong Page.
- **Multi-photo carousel (up to 4)**: the gallery picker adds multiple photos; the composer shows a swipeable `MediaCarousel` with `1/4` and **Cover** badges, per-photo **Edit** (crop/aspect/zoom/alt text, make cover, move left/right, remove) and screen-reader index announcements. Publishing uploads each photo with `published=false`, then creates **one** feed post with `attached_media`; a failed upload deletes already-uploaded photos and never creates the feed post.
- **Publish from anywhere**: Generate result header and Card Studio both seed a `FacebookDraftNotifier` draft (Card Studio captures its 4:5 PNG to a temp file first) and push `/facebook-compose` — no router `extra`.
- **Composer + photo pipeline**: message-first Facebook-style card, drag-to-reposition + pinch/slider zoom (1×–4×), crop presets **Feed 1.91:1 / Square 1:1 / Portrait 4:5**, **alt text** (≤420 chars, `alt_text_custom`), and a full feed `PostPreviewCard` preview. `FacebookImageCropper` bakes the visible frame into a **JPEG q85, ≤2048 px** on an isolate (with a `dart:ui` PNG fallback). Upload progress aggregates across photos ("Uploading photo 2 of 4 · 40%").
- **Scheduling**: bottom bar switches between **Post now** and **Schedule**; date/time picker validated to Graph's **10 minutes – 30 days** window, device-local UI with UTC timestamps. Scheduled posts send `published=false` + `scheduled_publish_time`, return no permalink, and can be cancelled (`DELETE /{post-id}`) or rescheduled (`POST /{post-id}`).
- **Service**: `FacebookPublisherService` on the pooled `ApiClient` — text → `/{page}/feed`, single photo → `/{page}/photos` multipart with `AppConstants.photoUploadTimeout` 60s, multi-photo → unpublished `/photos` uploads + `/feed` `attached_media` (JSON body), plus `listScheduled`, `deletePhoto`, `deletePost`, `updatePostMessage`. Tokens travel in form bodies or `Authorization: Bearer`, never URLs. `FacebookApiException` maps 190/200/10/4/17/32/613/506 plus `mediaUploadFailed`, `insightsUnavailable`, `pageTokenExchangeFailed`.
- **Post lifecycle**: published rows support **Edit caption** (`POST /{post-id}`) and **Delete post** (`DELETE /{post-id}`) with confirmation. Local history and thumbnails change only after Graph success; unsupported photo-post edits show “delete and repost” guidance.
- **History + insights**: last 50 records in `FacebookHistoryService` + `/facebook-history` split into **Published** and **Scheduled** tabs. Published rows show a compact stats line only when Facebook returns data, and open a `PostInsightsSheet` with reach, impressions, reactions (including per-type breakdown), clicks, engaged users and negative feedback. Refresh lives in the sheet and in pull-to-refresh (capped at 10 calls). Scheduled rows: due time, Reschedule, Cancel, and a best-effort Graph reconcile on open. Metrics stay `null` when unavailable — never fake zeros.
- **Comment moderation**: `FacebookCommentsService` + `/facebook-comments` list a post’s comments with pagination, author fallback, hidden badges, and Reply / Hide / Unhide / Delete actions. Requires `pages_manage_engagement`; missing permission and expired tokens show explicit states.
- **Storage cleanup**: the Settings → Facebook **Storage** tile reports post thumbnails, draft images and stale temp uploads. **Clean up** deletes unreferenced thumbnails, unused draft photos, orphaned draft folders, and cropped uploads older than 24 hours.
- **Photo pipeline + scheduling polish**: no-op crops upload the original file; repeated crops reuse a bounded cache. Multi-photo progress is byte-weighted and names the failing photo. Scheduling uses a date/time sheet with the device timezone, scheduled rows show a countdown, and history shows a **Not synced** banner when Graph reconciliation fails.
- **Configurable workflows + Stories**: Settings → Facebook → **Publishing workflows** defines Page post, Story, or **Page + Story** presets, with a default per Page. A workflow auto-applies when a draft starts; the composer shows a workflow chip and an editable Story card. Stories publish through `POST /{page-id}/photo_stories` using a dedicated unpublished photo (never the feed photo), with a **9:16 title-overlay image** generated locally. Feed success + Story failure is a partial success with **Retry Story** (no duplicate feed). Stories are post-now only; scheduling a Story workflow is blocked with switch-to-now/remove-Story choices.
- **Composer preview modes**: the eye preview offers **Light / Dark** and a **Visitor view**, scoped to a brand theme so app appearance is untouched.
- **Storage cleanup + disconnect**: full disconnect wipes Page tokens, history thumbnails, draft images and temp uploads. Settings → Facebook **Storage** reports and sweeps orphaned thumbnails, draft files and stale `oreamnos_fb_*` crops.
- **Drafts**: `/facebook-drafts` stores up to 20 drafts with their photos copied into app documents. Autosave plus an explicit **Save draft / Discard / Keep editing** close flow; open, duplicate, swipe-delete, and `New post` from the drafts screen. v9/v10 single-draft prefs migrate transparently.

### 5. Reading Mode & Customization
- Immersive, distraction-free reading screen with dynamic font sizing (Small, Medium, Large, Extra Large).
- Drag-down to dismiss modal sheet gesture.
- 9 themes via `AppThemeMode` (`lib/domain/models/app_theme_mode.dart:2`): **Light**, **Dark**, **Deep Blue**, **Midnight Noir**, **Solarized Light**, **Cyberpunk**, **Matchday**, **Forest**, **System** (follows OS `ColorScheme` via `DynamicColorBuilder` `lib/app.dart:80`); picker is horizontally scrollable `SingleChildScrollView` `lib/ui/features/settings/views/settings_screen.dart:55`.

### 6. Delight & Micro-Interactions
- **`EnhancedLoadingCard` (wired)**: 0–95% pulse `enhanced_loading_card.dart:12` shown during generate (`generatingStep` scraping→extracting, prompting→generating) + card-studio extraction; `SkeletonLoader` shimmer retained for log tiles/slivers.
- **`SuccessOverlay`**: 25-particle radial explosion + animated checkmark `lib/ui/core/widgets/success_overlay.dart:9` (once-ever flag `SharedPreferences hasShownSuccessOverlay` `generate_screen.dart:74`).
- **`InputClearButton`**: 2-step `Clear→Confirm?` 3s timer `lib/ui/core/widgets/input_clear_button.dart:8` + SnackBar UNDO `generate_screen.dart:93`.
- **`LinkPreviewCard`**: domain + `CachedNetworkImage` favicon + lazily scraped title/description `lib/ui/core/widgets/link_preview_card.dart:10`, 48dp dismiss, Extract action.
- **`FluidEditButton`**: EDIT↔SAVE morphing toggle for output edit mode with inline title/body editor (undoable).
- **`AppChip`**: 0.92 press-scale + long-press + animated select check (NeoChip motion parity).
- **`SwipeableOutputCard`**: swipe-to-copy/share `lib/ui/core/widgets/swipeable_output_card.dart:1`.

### 7. Analytics & Debugging
- **`LogService`**: In-memory ring buffer (200 entries) with debounced 500ms disk persistence and microtask notifications.
- **`DebugLogScreen`**: Filterable logs with text search, level chips (`DEBUG`, `INFO`, `WARN`, `ERROR`), tag chips, and details modal.
- **`UsageService`**: Historical token and latency tracking with provider success rates (`getSuccessRateByProvider`), average/fastest/slowest latency per provider, 7/30/90-day range filter, success donut + per-provider latency bars on the Usage screen.

---

## Architecture & Tech Stack

```
lib/
├── app.dart                   # ConsumerStatefulWidget + DynamicColorBuilder 9 themes + GoRouter (5 full-screen)
├── main.dart                  # configureDependencies() → ProviderScope + Notification/QuickSettings
├── config/theme/              # AppTheme 8 palettes + AppSpacing/AppColors(0095F6)/AppTypography/AppMotion
├── core/
│   ├── di/                    # get_it+injectable + register_module (SharedPreferences/SecureStorage encrypted)
│   ├── error/                 # failures.dart sealed Result<T>/Failure (active via IContentRepository)
│   ├── network/               # ApiClient pooled Dio 15s + Auth→Retry(4×500→60s jitter, Retry-After)→ErrorMapping(429→RateLimit)→Logging
│   └── repositories/          # IContentRepository/ICardRepository/ISettingsRepository/IUsageRepository + contentRepositoryProvider
├── data/services/             # Curators (Gemini/OpenAICompat via ApiClient + JsonCleaner isolate + GenerationPromptManager jsonSchema strict + refinePost + ResponseCleanup fallback) + TokenUsageSideChannel + WebScraper/ProviderApi (dio, Test Connection) + Preferences/Usage/Log/Export/ColorExtractor/GradientBuilder
├── domain/models/             # CardData 17 Freezed + CardTemplate 17 + CardFieldRegistry + CardConfig (10 ImagePos,5 ExportSize,5 Filter) + CuratedPost + UsageLog + CustomPill (stable id)
├── domain/services/           # GenerationPromptManager (length/technical/bullets/FORBIDDEN/refine/OCR) + CardPromptManager + CardDataNormalizer + JsonCleaner + ResponseCleanup + FootballOcrParser
└── ui/
    ├── core/                  # AppCard/AppButton/AppChip (press-scale)/AppInput/FluidEditButton + EnhancedLoadingCard + SuccessOverlay 25p + checkmark circle + RateLimitDialog (wait chip) + LinkPreviewCard (dismiss) + TypewriterMarkdown
    └── features/              # generate (Notifier<GenerateUiState> + RateLimit fallback + edit mode + QS clipboard + card: share routing) / card_generator (CardCanvasDispatcher 17 + PicsartToolDock 6 panels + StudioDeckSheet + TemplatePickerGrid + shuffle + Freeform drag) / settings (Test Connection) / usage (donut + latency bars + range filter) / shell
```

---

## Development & Commands

```bash
# Install dependencies
flutter pub get

# Run local device or emulator
flutter run

# Format check (CI gate — must be 0 changed)
dart format --output=none --set-exit-if-changed .

# Run static analysis (0 issues)
flutter analyze

# Run complete test suite (155 tests) with coverage
flutter test --coverage

# Run build runner for codegen (Freezed & json_serializable & injectable)
dart run build_runner build --delete-conflicting-outputs
```

---

## Testing & Quality Assurance

- **Unit & Widget Tests**: `155 tests` across 29 files — `UsageService(50)/LogService(200 ring,500ms persist)/Curators + 429 error paths/JsonCleaner/ResponseCleanup/Interceptors(400→friendly Auth/429→RateLimit)/Prompt detectors + length/refine + Gemini schema strip/CardData(17)/CardCanvasDispatcher 17/StudioDeck/VM shuffle + lists + bools/Edit mode/Readability/Scraper/ErrorState overflow` + `test/widget_test.dart` 4-tab nav; `test/generate_view_model_test.dart` Notifier via `contentRepositoryProvider`.
- **CI**: `.github/workflows/ci.yaml:20` pinned `3.47.1` → `pub get` → `dart format --output=none --set-exit-if-changed .` (0) → `flutter analyze` (0) → `flutter test --coverage` (155) → `dart run build_runner build` (freezed/json/injectable) on push/PR.

See `docs/architecture.md`, `docs/design-system-threads.md`, `docs/migration-threads-convergence.md`, `docs/parity-matrix.md`, `docs/baseline-phaseD.md`, and `CHANGELOG.md` for details.
