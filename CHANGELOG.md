# Changelog — Oreamnos

## v10 — Facebook Photo Pipeline + Scheduling (2026-11-04)

- **Crop control:** drag-to-reposition and pinch/slider zoom (1×–4×) on the inline photo preview; crop presets (Feed 1.91:1 / Square 1:1 / Portrait 4:5) and **Reset crop**. Preview and upload share the same clamped rect math (`FacebookImageCropper.cropRectFor`).
- **Alt text:** 420-character field sent as `alt_text_custom`, plus a screen-reader label on the preview card.
- **Smaller uploads:** JPEG q85 ≤2048 px encoded on a background isolate via the `image` package (EXIF baked, `dart:ui` PNG fallback). No re-encode when the crop is a no-op.
- **Scheduling:** **Post now / Schedule** switch with date+time picker, validated to Graph's 10 min – 30 days window; `published=false` + `scheduled_publish_time` on feed/photo calls; scheduled success view with the due time and Cancel schedule.
- **Scheduled history:** `FacebookPostRecord` gains `status` / `scheduledAt` / `pageId` / `pageName` / `localImagePaths` (v9 JSON migrates) and the history screen splits into **Published** / **Scheduled** tabs with Reschedule, Cancel (DELETE), and best-effort `/scheduled_posts` reconciliation.
- **Drafts:** v9 `imagePath` drafts migrate into the new media list; the composer shows a one-shot "Draft restored" SnackBar with Discard.
- **Tests:** 385 green (+14: zoom/offset crop math, schedule window boundaries, scheduled publish + history, missing schedule rejection, v9 draft migration, alt text/crop state, scheduled publisher form fields, DELETE/list parsing, scheduled record persistence). `dart format` 0, `flutter analyze` 0, debug APK builds.

## v9 — Facebook Composer Preview + Workflow Polish (2026-11-04)

* **Facebook-style composer:** Page identity row (avatar/name/Public), message-first borderless editor, compact Photo/Camera/Hashtags bar, and a **single composer card** — the photo preview and crop controls fold into it once an image is attached, instead of rendering a second text-only post section. The eye icon opens the full feed `PostPreviewCard` (avatar, "Just now · Public", message, image, Like/Comment/Share row, estimated link host).
* **Crop/aspect control:** `FacebookImageAspect` presets (Feed 1.91:1 · Square 1:1 · Portrait 4:5) drive both the preview frame and `FacebookImageCropper` — a `dart:ui` center crop baked into the uploaded PNG (≤2048px, no new package) so Facebook can't re-crop the card.
* **Workflow:** debounced draft autosave/restore, "Discard draft?" PopScope guard, image-file pre-flight (purged temp cards get a fixable message), Dio `onSendProgress` upload percentage, terminal published state (no duplicate posts/history), and a success view with thumbnail + View on Facebook / Copy link / Publish another / Done.
* **History:** records now keep the full caption and a local thumbnail copy in app documents (temp files are purged), shown in `/facebook-history`; long-press gains **Reuse caption**. Removing/clearing history deletes the thumbnails.
* **Connect:** `GET /me?fields=id,name,picture{url}` persists the Page avatar for the composer/preview.
* **Tests:** 371 green (+13: crop-rect math, aspect change, draft autosave/restore, missing-file pre-flight, second-publish guard, hashtag append, `PostPreviewCard` image/placeholder states); `dart format` 0, `flutter analyze` 0.

## v8 — Facebook Page Publishing (2026-11-03)

* **Stages 1–4:** Graph service + formatter (strict markdown→plain, hashtags kept), secure-token connection flow with `GET /me` verification, compose screen with text/photo publishing and per-kind error panels, and a capped-50 publish history with Settings integration.
* **Token safety:** Page token only in POST bodies or `Authorization: Bearer` — never URL query params (the debug interceptor's redaction doesn't cover `access_token=`), never in `LogService`, never in prefs.
* **Network:** pooled `ApiClient` + form/`FormData` bodies; text posts keep the 15s pool window, photo uploads get `photoUploadTimeout` 60s (a client abort on a slow upload causes a server-side post and a duplicate 506 on retry).
* **Error taxonomy:** 190 → expired (Reconnect), 200/10 → permission, 4/17/32/613 → rate limit, 506 → duplicate (edit to republish), transport → network; unknown keeps Facebook's message.
* **Tests:** 339 green (46 new: service error kinds + token-in-body invariants, formatter cases, connection VM, draft publish incl. offline/duplicate/expired, history cap/restart); `dart format` 0, `flutter analyze` 0.

## v7 — Quota Fix + Share Intent Repair (2026-11-01)

* **Rate-limit root cause:** receive/send timeouts are no longer retried (`RetryInterceptor` — an aborted generation already consumed quota; formerly one tap on Gemini `generateContent` counted up to 5 requests: 15s receiveTimeout × 4 retries). Generation requests get a per-request receive window `AppConstants.generationReceiveTimeout` 90s (pool base stays 15s; `extractCardData`/`rewriteField` use 60s); VM `generateStructuredPost`/`refinePost` guards aligned to 90s; `maxOutputTokens: AppConstants.defaultMaxTokens` bounds unbounded-schema runs.
* **Silent fallback is volatile:** auto-hop on 429/402 no longer rewrites the persisted `selectedProvider`/`selectedModel` — hops travel via `forceProvider` and `_resolveModelId` (per-provider stored model or provider default; never another provider's selected model). Persistent switching reserved for the explicit `RateLimitDialog` path. 429 cooldown floor 30s→60s + combined share attempt budget `_maxAttemptsPerShare = 4`.
* **Cancellation:** `CancelToken` plumbed `GenerateViewModel` → `IContentRepository`/`IContentCurator` → `ApiClient.post/get` — superseded sessions, VM timeout expiry, `reset()`, vision 60s timeout and `ref.onDispose` all cancel in-flight provider requests (no more background quota burn from orphaned generations).
* **Share intent cold-start fix:** removed the pre-init `reset()` that destroyed fresh shares delivered while the app was closed (the "share lands on a blank Generate screen" regression). Order restored: `getInitialMedia` → fingerprint load → handle → reset. Persisted fingerprint (`share_initial_fingerprint`) suppresses Android cached-process stale replays on the initial path; `app.dart` in-flight share pin expires after 8s.
* **Tests:** 293 green across 43 files (+timeout retry policy, + share fingerprint/stale-replay, volatile-fallback contract rewritten); `dart format` 0, `flutter analyze` 0.

## v6 — Gemini 400 Fixes (2026-09-04)

* **Structured output:** new `GenerationPromptManager.geminiResponseSchema` (recursive `additionalProperties` strip — Gemini rejects that field with HTTP 400); swapped into both Gemini schema call sites; OpenAI strict schema untouched. One-shot schema-less retry if Gemini ever names `response_schema` in a 400 again.
* **Friendly errors:** `ErrorMappingInterceptor` maps 400 invalid-key bodies to "rejected the API key… Settings → API Key", truncates all raw bodies to 220 chars; `ProviderApiService` reuses mapped messages instead of raw `DioException` dumps.
* **Overflow:** `ErrorState` message is scrollable + height-capped — long provider errors can no longer overflow the model dialog (or any parent).
* **Tests:** 155 green (schema strip, 400 mapping/truncation, dialog overflow widget).

## v5 — Full Original Parity Pass (2026-09-04)

* **Correctness:** `getMatchColors` away.second fix, exact Android club hex + named presets, 4-stop scrim math, standings 5-row cap, `CustomPill.id` stable identity.
* **Resilience:** `RateLimitFailure(retryDelayMs/providerName/waitTimeMessage)` + Gemini `details.retryDelay` parsing + dialog wait chip (policy kept: retry-then-dialog); OpenRouter headers, `max_tokens:2048`, 30/60s OpenAI timeouts; offline `defaultModelId`; Test Connection tile.
* **Prompts:** length multipliers + technical branch + FORBIDDEN + detectors + `buildRefinementPrompt`/`buildPromptFromOcr`; full `refinePost` pipeline (curators + repository + VM); `ResponseCleanup` port wired into markdown fallbacks; scraper unwanted-elements/promo/bare-URL parity.
* **Studio:** undoable `shuffleDesign`, `TemplatePickerGrid` with mini previews, Deck list/bool editors (`updateCardListField`/`setCardBoolField`), Oreamnos gallery album, public `DraggableCanvasElement`.
* **UX:** output edit mode (`FluidEditButton` + inline editor), link preview dismiss + fetched metadata, QS-tile clipboard pickup, `card:` share-to-studio routing, success donut + latency bars + 7/30/90d filter, checkmark circle, chip motion.
* **Tests:** 148 green (`parity_utils`, `usage_stats_parity`, VM shuffle/lists/bools, edit mode); `dart format` 0, `flutter analyze` 0.

## v4 — Card Studio Depth + Resilience Closure (2026-09-03)

* **Studio Deck:** new `StudioDeckSheet` bottom sheet (`lib/ui/features/card_generator/widgets/studio_deck_sheet.dart`) — generic registry-driven field editor, MISSING amber chips, dashed missing borders, per-field AI polish, template switch with cached re-extraction.
* **Loading:** `EnhancedLoadingCard` wired into generate flow (`generate_screen.dart:_buildResultArea`) by `generatingStep` (scraping→extracting, prompting→generating) + card-studio extracting states; sealed `CardData` 17 kept (no `values`-map rebuild).
* **Release:** `proguard-rules.pro` hardened (keep rules for secure storage, workmanager, exif, okhttp), `android/key.properties` + `*.jks` gitignored (rotate committed secret), parity matrix `docs/parity-matrix.md`.
* **Tests:** `preferences_service_test`, curator 429/error paths, `studio_deck_sheet_test`.

## v3 — Phase C/D Baseline (2026-08-27..09-02)

* **Card engine:** sealed `CardData` 17 + `CardTemplate` 17 + `CardCanvasDispatcher` 17 + `CardFieldRegistry` + `CardPromptManager` char caps + `CardDataNormalizer` + `CardSlot`/`FadeHairline`/`Vignette`/`SubjectGlow` + `template_intent` suggestion + undo/redo 50 + 5 export sizes / 10 positions / 5 filters / watermark / fonts / shadow-glow-blur.
* **Network/resilience:** pooled dio `ApiClient` 4 interceptors (retry 4×500ms→60s+jitter+Retry-After, 429→RateLimitFailure), 15s timeouts + 30s VM guard, `RateLimitDialog` + `AiProvider.nextFallback`, token side-channel (`usageMetadata`/`usage`) with estimate fallback, `JsonCleaner.decodeIsolate`.
* **Nav/themes:** 4-tab shell + 5 fullscreen, 9 theme modes (8 palettes + system), skeleton + stagger + success overlay 25p + two-step clear + link preview og:title/favicon + injected `LogService` + `Haptics` + debug badges.
* **Quality:** `dart format` 0, `flutter analyze` 0, 100+ tests across 22 files, CI pinned `3.47.1`.

## v2 — Threads Convergence (2026-08-26)

* **Design system:** `Wrap` `settings_screen.dart:55` → `SingleChildScrollView` horizontal `Row` (9 modes `lib/domain/models/app_theme_mode.dart:2` `light/dark/deepBlue/midnightNoir/solarizedLight/cyberpunk/matchday/forest/system`); `SettingsTile` `brutalist→Threads` `BorderRadius.zero→borderRadiusSm` + `arrow_forward→chevron_right_rounded` `lib/ui/core/widgets/settings_tile.dart:35`; FAB `elevation 2→1` `hashtag_manager_screen.dart:186`.
* **Card engine:** `CardCanvas` 4-case `card_canvas.dart:110` → `CardCanvasDispatcher` 17 `renderers/card_canvas_dispatcher.dart:33` + `CardConfig` `lib/domain/models/card_config.dart:36`; `CardGeneratorViewModel:184` retains `polished` `CardData` 17 (`lib/domain/models/card_data.dart:104`); `CardDataExtractor:24` `template?, isRefresh` → `IContentCurator.extractCardData(template)` `lib/domain/services/content_curator.dart:25` + `CardPromptManager` 16 schemas `card_prompt_manager.dart:47`.
* **Rate limit:** `RateLimitDialog` `suggestedFallbackProvider/currentProviderName/onRetryWithFallback` + `barrierDismissible:false` `lib/ui/core/dialogs/rate_limit_dialog.dart:3`; `GenerateScreen` `ref.listen rateLimited` `lib/ui/features/generate/views/generate_screen.dart:118` with `AiProvider.nextFallback:21` chain; inline `ErrorState:693` fallback when no model.
* **Network:** `WebScraperService` `http.get 8s` + `ProviderApiService` `http` + `curators rewriteField ?key=` leak `gemini_curator.dart:214` → `@lazySingleton` dio via pooled `ApiClient` 4 interceptors `api_client.dart:23` (`Auth extra apiKey/provider`, `ErrorMapping 429→RateLimitFailure`, `Retry 4×500→60s`, `Logging`); `ProviderApiService:17` + `WebScraperService:10` via `injection.config.dart:57`.
* **Build:** `dart format` 0 changed (was 134/150), `flutter analyze` 0 (was 14), `flutter test --coverage` 75, `build_runner` 0 on 2nd run. Docs: `docs/architecture.md`, `docs/design-system-threads.md`, `docs/migration-threads-convergence.md`, `docs/baseline-phaseB.md`.

## v1 — Initial Flutter (pre-2026-08-25)

* Baseline `docs/baseline-phase0.md` — 11 info issues, 8 tests, `riverpod_generator` deferred.
