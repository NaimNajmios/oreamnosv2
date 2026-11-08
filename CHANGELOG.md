# Changelog — Oreamnos

## v24 — Publishing Handoff, Performance & Best Times (2026-11-08)

- **Generate → Publish handoff:** generated content now appears automatically in the Publish tab (`publishHandoffProvider` derived from the Generate tab). The shell shows a dot on the Publish tab while content is waiting. **Publish now** opens the composer for review; scheduling or publishing consumes the handoff. The Generate screen’s header Facebook icon became a full-width bottom CTA landing on Publish.
- **Publish hub redesign:** ready-to-publish card, Page performance card, best posting windows, and compact Drafts/Scheduled/Published counts replace the three stat cards.
- **Current post metrics:** replaced retired June-2026 metrics with `post_total_media_view_unique`, `post_reactions_by_type_total` and `post_activity_by_action_type`; legacy cached values stay visible but labelled. Engagement (`reactions`, `comments`, `shares`) is fetched separately so it cannot be taken down by a retired insight metric. Metric names are centralized in `FacebookMetricNames`.
- **Page performance:** new `/facebook-performance` screen with 7/28-day filter, daily chart, media views/follows/engagements KPIs, recent posts and a 30-minute cache. Requires `read_insights` + `pages_read_engagement` and ANALYZE.
- **Estimated earnings:** Content Monetization earnings shown as estimated in Page currency with restatement/payout caveats; a zero is never treated as “no earnings”.
- **Best time to post:** deterministic, local, non-AI weekday/hour scoring from the Page’s own published history (comments ×2, shares ×3, 21-day half-life). Needs 2+ samples per bucket; suggests times in the schedule sheet and hub.
- **Tests:** 517 tests, including new insight/engagement parsing, Page insights, best-time heuristic, handoff lifecycle, and token-out-of-URL assertions.

## v23 — Uppercase Persistence + Chip Contrast (2026-11-05)

- **Uppercase always persists:** the title-uppercase display preference is saved/restored independently of the broader “Persist generation options” setting. `reset()` keeps it.
- **Dark-theme chip contrast:** selected `AppChip` pills now use `onPrimaryContainer` for text/icons (white in dark themes) and a foreground-derived border instead of accent-on-accent. Selected labels use heavier weight; disabled pills are visibly muted.
- **Tests:** uppercase persistence with options off, reset retention, and AppChip selected/disabled/custom-color contrast.

## v22 — Facebook Photo Upload 400 Diagnostics (2026-11-05)

- **Graph error details:** the publisher now logs `error.code`, `error_subcode`, `message`, `error_user_title` and `error_user_msg` (debug only, no token/caption).
- **MIME/filename correctness:** multipart uploads use the real extension and content type (`oreamnos_card.jpg`/`image/jpeg` or `.png`/`image/png`) instead of always claiming `.png`.
- **Graph-safe formats:** no-op crops return the original only for JPEG/PNG; HEIC/WebP/unknown files are re-encoded to JPEG.
- **Upload preflight:** missing/empty files and files over 10 MB fail locally with a fixable message before any request.
- **Image rejection mapping:** Graph code 324 maps to `mediaUploadFailed` with “Facebook rejected the image. Try a JPEG or PNG under 10 MB.”
- **Tests:** multipart filename/content type, code 324 mapping, empty-file preflight, and unsupported-extension re-encode.

## v21 — Facebook Publishing Response Audit (2026-11-05)

- **Shared Graph response guard:** publisher, Page verification, insights and comments all use `facebookRequireObject`; a 200 HTML/plain/proxy body becomes `unexpectedResponse`, never a fake network failure or an empty result.
- **Insights:** `GET /{post-id}` now uses dynamic parsing with a 60 s window; non-JSON 200s show the unexpected-response message instead of “no insights”/network.
- **Comments:** list/reply/hide/delete use dynamic parsing. Comment writes are marked `graphWrite` (never auto-retried) with 60 s send/receive windows. A non-JSON comments 200 shows the unexpected-response message instead of an empty list.
- **Page/verify taxonomy:** non-JSON 200s in `/me` and `/me/accounts` now use `unexpectedResponse` consistently.
- **Tests:** HTML 200 coverage for insights/comments/Page verification, plus comment-write `graphWrite`/timeout assertions.

## v20 — Facebook Publish Write Hardening (2026-11-05)

- **Non-JSON 200 responses:** all publish/upload/story/schedule writes now use `post<dynamic>`/`delete<dynamic>` and parse defensively. An HTML/proxy/captive-portal body becomes **unexpectedResponse**, not a fake network failure.
- **Write timeouts:** feed/multi-photo/schedule writes get 60 s receive windows; photo uploads get 120 s send + receive windows (previously the 15 s BaseOptions send timeout could abort large uploads).
- **No auto-retry for writes:** Graph `POST`/`DELETE` requests are marked `graphWrite` and never retried by `RetryInterceptor`, avoiding duplicate posts when a response is lost. Only safe GETs retry; the dialog/composer offers manual retry.
- **Publish uncertainty:** transport/unexpected-response failures during a write enter **publishUncertain** instead of “failed”. The draft is preserved, no history row is written, and the UI offers View Published / View Scheduled / Try again (with duplicate warning) / Discard.
- **Tests:** HTML 200 publish responses, write timeout values, no Graph-write auto-retry, and uncertain-state draft preservation.

## v19 — Facebook Connect Network Diagnostics (2026-11-04)

- **Accurate transport errors:** connection failures now distinguish timeout, DNS/connection, TLS/certificate, cancellation and unknown instead of showing “No connection” for everything.
- **Non-JSON 200 responses:** connect/verify read responses as raw data and parse defensively. A 200 HTML/captive-portal/proxy page now shows “Facebook returned a web page instead of JSON…” instead of a fake network error.
- **Exactly one exchange per tap:** a received HTTP response is terminal. The app no longer adds a second `/me/accounts` request after a success; Dio’s connection-level retry remains the only transport retry.
- **Dialog UX:** errors clear as soon as the token is edited; a **Try again** action retries without re-pasting; loading keeps the button disabled.
- **Logging:** debug `[DIO]` lines include the Dio error type (`connectionError`, `receiveTimeout`, `badCertificate`, …) with URLs redacted.
- **Tests:** network issue mapping, transient retry vs auth no-retry, and existing connect dialog/graph tests.

## v18 — Uppercase Title Toggle (2026-11-04)

- **Title formatting:** the Generate output adds an **Uppercase** chip next to **Title**. When enabled, the title renders in uppercase with slightly wider tracking so it reads separately from the body.
- **Consistent copy/share:** the uppercase title flows into copy, share, reading mode and the seeded Facebook composer draft; the body, hashtags and source keep their original case.
- **Persistence:** the toggle is saved with the existing generation options and restored on launch when option persistence is enabled.
- **Accessibility:** the original title remains the semantics label, so screen readers don’t spell out the uppercase text.
- **Tests:** toggle state/persistence, copy formatting, and TitleBlock rendering.

## v17 — Dedicated Publish Tab + Hub (2026-11-04)

- **New bottom-nav section:** Generate · Cards · **Publish** · Usage · Settings. `/publish` opens a dedicated publishing hub.
- **Hub UI:** Page identity/switcher, connection state, default workflow, **Create a post**, Drafts/Scheduled/Published counts, next scheduled post with countdown, continue-writing card, recent posts with insights and Story status/retry, and Manage links for Drafts, Published, Workflows and Storage.
- **Settings cleanup:** the Facebook section (Page publishing, Published Posts, Drafts, Workflows, Storage) moved out of Settings into the Publish tab.
- **History deep links:** `/facebook-history?tab=scheduled|published` opens the requested tab; the hub uses it for Up next and recent posts.
- **Drafts provider:** `facebookDraftsProvider` keeps hub counts/list fresh after composer/drafts navigation and pull-to-refresh.
- **Storage dialog:** extracted for reuse by the hub.
- **Tests:** 5-tab navigation, Publish hub empty/connected states, Settings no longer exposes publishing, existing 466 tests still green.

## v16 — Facebook Workflows + Page Stories (2026-11-04)

- **Publishing workflows:** reusable presets for Page post, Story, or Page + Story, with a default per Page. Settings gains `/facebook-workflows`; drafts auto-apply the default and the composer exposes a workflow chip, per-post toggles, and an editable Story title.
- **Page Stories:** `POST /{page-id}/photos` (`published=false`) followed by `POST /{page-id}/photo_stories` via `photo_id`. Stories use a dedicated 1080×1920 JPEG with the **short title baked into the image** (the API has no caption field), never the published feed photo.
- **Partial success:** feed + Story publishes as two destinations. If the Story fails after the feed succeeds, the feed stays live, history marks **Story failed**, and **Retry Story** publishes only the Story.
- **Automation:** per-Page defaults mean Generate → Publish can post to Page + Story in one action. Story-only posts and generated gradient cards are supported.
- **Constraints handled:** Stories are post-now only (scheduling is blocked with clear choices); permission/unsupported errors surface `storyUnavailable` without retry loops.
- **Tests:** workflow store/defaults/cap, title extraction, 1080×1920 composer output, Story Graph bodies, feed+Story success, partial failure, retry isolation, and scheduling rejection.

## v15 — Facebook Gap Closure (2026-11-04)

- **Preview modes:** Light/Dark + Visitor view in the feed preview, scoped to a brand theme.
- **Crop pipeline:** no-op crops return the original file; repeated crops reuse a bounded in-memory cache.
- **Progress:** byte-weighted multi-photo progress and “Photo n of m failed” errors; new `compressing`/`partialSuccess` phases.
- **Scheduling UX:** date/time sheet with timezone, scheduled row countdown, published/Story status chips, and a **Not synced** history banner with retry.
- **Lifecycle/security:** full disconnect now deletes history thumbnails, draft images and temp uploads; 190 errors mark the connection expired from history, insights and comments; comments permission errors no longer loop on retry.
- **Maintenance:** daily storage sweep + 15-minute scheduled reconcile on app start (both throttled).
- **Pages:** Page switcher gains **Disconnect this Page** and **Re-import from user token**; legacy Page keys remain readable for one release.
- **Drafts:** creating a new draft at the 20-draft cap asks before deleting the oldest; history records store per-photo metadata.
- **Tests:** storage eviction/sweep, workflow/title/composer, cropper cache, story Graph calls, partial success, and 190 propagation.

## v14 — Facebook Comment Moderation (2026-11-04)

- **Comments service:** `FacebookCommentsService` lists `/{post-id}/comments` with pagination (`after` cursor, 25 per page, reverse chronological), replies via `POST /{comment-id}/comments`, hides/unhides via `POST /{comment-id}` (`is_hidden`), and deletes via `DELETE /{comment-id}`. Tokens stay in form bodies or `Authorization: Bearer`.
- **Comments screen:** new `/facebook-comments` route with author avatars/initials, relative time, hidden badges, reply sheet, load-more, pull-to-refresh, and confirmed deletion. Missing `pages_manage_engagement` and expired tokens show explicit states; comment text is never persisted or logged.
- **History entry point:** published rows gain **Comments** in the long-press menu.
- **Tests:** comment parsing (missing authors, cursors), reply/hide/delete request bodies, permission/expired mapping, pagination dedupe, and controller action behavior.

## v13 — Facebook Post Lifecycle + Richer Insights + Storage Hygiene (2026-11-04)

- **Delete published posts:** `DELETE /{post-id}` with confirmation; local history and thumbnails are removed only after Graph success.
- **Edit captions:** `POST /{post-id}` with `message`; `FacebookPostRecord` gains `editedAt` and the history row/snippet updates. Unsupported edits show “delete and repost” guidance without mutating local state.
- **Richer insights:** adds total impressions, engaged users, negative feedback, and per-reaction-type counts to the existing reach/reactions/clicks model. The new `PostInsightsSheet` renders only metrics Facebook returned and exposes refresh; no fake zeros.
- **Storage hygiene:** history eviction now deletes evicted thumbnails; draft saves prune files for removed photos; `FacebookStorageService` reports thumbnail/draft/temp usage and sweeps orphans plus cropped uploads older than 24 hours. Settings → Facebook gains a **Storage** tile with **Clean up**.
- **Tests:** publisher delete/edit calls, unsupported-edit mapping, history `updateMessage`/richer-insight persistence, eviction thumbnail cleanup, draft pruning, storage report/sweep idempotence, and expanded insights parsing.

## v12 — Facebook Multi-Page + Drafts (2026-11-04)

- **User-token connect:** one user token is exchanged via `GET /me/accounts`; every Page is discovered and only the derived Page tokens are persisted under `facebook_page_token_<pageId>`. The user token is discarded immediately and never written to prefs, secure storage, logs or drafts.
- **Page switcher:** `PageSwitcherSheet` from the composer header changes the active Page; `FacebookConnectionDialog` keeps the Page-token path plus "Disconnect this Page" / "Disconnect all".
- **Draft ownership guard:** drafts are stamped with `pageId`; switching Pages with a non-empty draft offers **Switch target / Duplicate draft / Keep original Page**.
- **Multi-draft store:** `facebook_drafts` (cap 20, newest first) with photos copied into `<appDocs>/facebook_drafts/<draftId>/` so temp cleanup cannot break them. Autosave writes through the store; the back gesture offers **Save draft / Discard / Keep editing**; publishing or discarding deletes only that draft.
- **Drafts screen:** new `/facebook-drafts` route with thumbnail, caption, Page, photo count and relative time; open, duplicate, swipe/long-press delete, `New post` FAB, and orphan pruning. v9/v10 single-draft prefs migrate into the store.
- **Legacy migration:** the v11 single-Page connection moves idempotently into a Page entry + per-Page token.
- **Tests:** 421 green (+36 across multi-photo state/publish/cleanup, insights parsing/cache, per-Page token storage/migration, user-token exchange (asserting the user token is never persisted), Page service parsing/error mapping, Page switching/disconnect, draft store cap/duplication/image copying/legacy migration). `dart format` 0, `flutter analyze` 0.

## v11 — Facebook Multi-Photo + Insights (2026-11-04)

- **Multi-photo composer (up to 4):** gallery picker adds multiple images; swipeable `MediaCarousel` with `1/4` and **Cover** badges; per-photo edit sheet for crop/aspect/zoom/alt text, make cover, move left/right and remove; screen-reader index announcements.
- **Multi-photo publish:** each photo uploads with `published=false`, then one `POST /{page}/feed` carries `attached_media` (JSON body, token never in the URL). Progress aggregates across photos; any upload/feed failure aborts before/after the feed post and best-effort `DELETE`s uploaded photos.
- **Insights:** `FacebookInsightsService` reads `post_impressions_unique`, `post_reactions_by_type_total` and `post_clicks`; `FacebookPostRecord` caches them and the history row shows `👁 · 👍 · 🔗` only when data exists (never fake zeros). Long-press **Refresh insights** + pull-to-refresh (capped), no requests for scheduled posts.
- **Models/errors:** stable media ids, `FacebookLimits` (4 photos, 420 alt chars), record insights fields (v10 JSON loads as null), and `mediaUploadFailed` / `insightsUnavailable` / `pageTokenExchangeFailed` kinds.
- **Tests:** multi-photo Graph bodies, failed-upload cleanup, progress aggregation, insights parsing/cache, media cap/reorder/cover. `dart format` 0, `flutter analyze` 0.

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
