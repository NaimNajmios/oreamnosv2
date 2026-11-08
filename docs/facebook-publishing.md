# Facebook Publishing

State machine, Graph calls, timezone rules, token storage, media lifecycle,
post management, comments, storage, workflows and Story cross-posting.
Release v16 (gap closure + configurable workflows + Page Stories).

## Navigation (v17, handoff v24)

Publishing owns the **Publish** bottom-nav tab (`/publish`). The tab root is
`PublishHubScreen`:

- Page identity + switch/manage
- **Ready to publish** card (generated content from the Generate tab)
- Performance card + detailed `/facebook-performance` view
- Best posting windows (local, non-AI)
- Drafts / Scheduled / Published counts
- Up next scheduled post (opens history `?tab=scheduled`)
- Continue writing (active or newest draft)
- Recent posts with insights and Story status/retry
- Manage: Drafts, Published, Workflows, Storage

Generated content flows to Publish without router `extra`:
`publishHandoffProvider` derives a `PublishHandoff` from
`generateViewModelProvider`. The shell shows a small dot on the Publish tab
while a handoff is waiting. **Publish now** opens the composer for final review;
it never posts immediately. Scheduling or publishing consumes the handoff, and
a new generation surfaces again.

The Generate screen keeps a full-width **Publish on Facebook** CTA below the
generated card (previously a header icon) that lands on the Publish tab. When
no Page is connected it opens the connection dialog instead.

Composer, history, drafts, workflows and comments remain full-screen pushes
from the hub. Settings no longer contains Facebook tiles. Card Studio's publish
icon remains a shortcut into the composer and applies the Page's default
workflow.

## Security contract

- **Connection errors are transport-specific:** `FacebookApiException.networkIssue` distinguishes timeout, DNS/connection, TLS, cancellation and unknown. “Can’t reach Facebook” never implies an invalid token.
- A received HTTP response is terminal: **never** issue a second `/me/accounts` request after a 200. Dio’s transport retry is the only automatic retry; the dialog’s **Try again** handles manual retry.
- Connect/verify parse `get<dynamic>` responses defensively: a 200 HTML/plain/captive-portal body becomes “Facebook returned a web page instead of JSON…” (not `network`).

- **Page tokens** live only in `flutter_secure_storage` under
  `facebook_page_token_<pageId>` and are only ever sent in a form/JSON body or
  an `Authorization: Bearer` header.
- **User tokens** used for `/me/accounts` are exchanged in memory and
  discarded immediately. They are never written to prefs, secure storage,
  drafts, logs or analytics.
- Never put any token in a URL query, a log, analytics, prefs, draft JSON or
  history.
- Drafts, history and Page entries store local paths/identity only.
- `disconnectFacebook()` wipes every per-Page token, Page entries, history and
  all drafts. `disconnectFacebookPage(pageId)` removes one Page token and
  promotes the next Page.

## State machine

```
editing → compressing → uploading → publishing → published
        ↘ scheduling → scheduled
        ↘ publishError (retryable | needsReconnect)
```

- `FacebookComposePhase` is `editing | compressing | publishing | published |
  scheduled | partialSuccess | publishError`.
- `partialSuccess` means the feed is live but the Story failed; retry the Story
  only.
- `FacebookPublishMode { now, scheduled }` lives on the draft and is autosaved.
- Stories are **post-now only**; scheduling a Story workflow is rejected before
  any network call.

## Multi-photo (v11)

`FacebookComposeState.media` is a `List<FacebookMediaItem>` capped at
`FacebookLimits.maxPhotos = 4`. Each item stores `id`, `path`, `aspect`,
`zoom` (1–4), normalized `offset` (−1..1) and `altText` (≤420). The first item
is the cover. `moveMedia`, `makeCover`, `removeMedia` and `updateMedia` are
autosaved.

Publishing:

1. Empty list → `POST /{page}/feed`.
2. One item → existing `POST /{page}/photos` path.
3. 2–4 items → sequential `POST /{page}/photos` with `published=false`, then a
   single `POST /{page}/feed` with `attached_media: [{media_fbid}]` in a JSON
   body (token in the body). Upload progress aggregates as
   `(completed + currentFraction) / total`.
4. Any failure aborts before the feed post and best-effort `DELETE`s the
   already-uploaded photo ids.

## Post lifecycle (v13)

Published history rows support:

- **Edit caption** — `POST /{post-id}` with `message` + token in the form body.
  History updates `message`, `snippet` and `editedAt` only after Graph success.
  Unsupported edits surface “Facebook doesn't allow editing this post's
  caption. Delete and repost instead.”
- **Delete post** — `DELETE /{post-id}` with the token in the form body, behind
  a confirmation dialog. The local record and thumbnails are removed only after
  Graph success.

Scheduled rows keep Reschedule/Cancel; failed rows keep local-only removal.

## Insights (v11, expanded v13, migrated v24)

`GET /{post-id}?fields=insights.metric(post_total_media_view_unique,post_reactions_by_type_total,post_activity_by_action_type)`
with the token in `Authorization: Bearer`. `FacebookInsightsService` parses the
nested `insights.data[]` defensively:

- `post_total_media_view_unique` → `uniqueViewers`
- `post_reactions_by_type_total` → per-type map + summed `reactions`
- `post_activity_by_action_type` → `activityByActionType`

Meta retired `post_impressions`, `post_impressions_unique`, `post_engaged_users`,
`post_negative_feedback` and `post_clicks` in June 2026. Those fields remain on
`FacebookPostRecord` only for records cached before the change and are labelled
"(earlier metric)" in the UI. Metric names live in `FacebookMetricNames`.

Engagement is fetched separately:
`GET /{post-id}?fields=reactions.summary(true),comments.summary(true),shares`
→ `reactions`, `comments`, `shares`. A retired insight metric can therefore
never take the engagement badges down. Missing or malformed values stay `null`.
`FacebookPostRecord` caches all fields. Pull-to-refresh runs engagement then
insights for the newest 10 records; insight refreshes merge non-null values and
never wipe cached data.

## Page performance + earnings (v24)

`FacebookPageInsightsService` calls `GET /{page-id}/insights` with
`metric=page_media_view,page_follows,page_post_engagements&period=day`, a
28-day range, and the token in `Authorization: Bearer`. Results merge per day,
tolerate a missing metric, and cache in `facebook_page_insights_<pageId>` (30 min
TTL, no tokens). Requires `read_insights` + `pages_read_engagement` and the
ANALYZE Page task; a 403 explains that.

`FacebookMonetizationService` requests
`content_monetization_earnings,monetization_approximate_earnings`. Earnings are
shown as **estimated**, in Page currency, with restatement and payout caveats.
A zero never means “no earnings” — it can also mean not enrolled.

The hub card and `/facebook-performance` screen present media views, follows,
engagements, a daily chart (7/28-day filter) and recent posts. `refresh()`
fetches earnings first and treats failure as optional so performance still
loads.

## Best time to post (v24)

`BestTimeToPost` is deterministic, local and non-AI: it scores weekday/hour
buckets from the Page's own published records, weighting comments ×2 and shares
×3, with a 21-day half-life. A bucket needs at least 2 samples; 3+ is
“confident”. No network or model is involved. `nextOccurrence` returns the next
device-local slot at least 10 minutes ahead. With too little history the UI
explains why instead of inventing a time.

## Comments (v14)

`FacebookCommentsService` moderates a published post's comments:

| Action | Call |
|---|---|
| List | `GET /{post-id}/comments?fields=id,message,from{id,name},created_time,like_count,comment_count,is_hidden,can_hide,can_remove,permalink_url&limit=25&order=reverse_chronological&after=<cursor>` |
| Reply | `POST /{comment-id}/comments` (`message`) |
| Hide / unhide | `POST /{comment-id}` (`is_hidden=true/false`) |
| Delete | `DELETE /{comment-id}` |

- Pagination uses `paging.cursors.after`; comments are deduplicated by id.
- Missing `from` falls back to “Facebook user”.
- Writes and deletes require `pages_manage_engagement`; missing permission shows
  a dedicated message, and 190 offers Reconnect.
- Comments are live-only: text is never persisted, logged, or cached in prefs.

## Storage hygiene (v13)

- History eviction at the 50-record cap deletes evicted thumbnails.
- Every draft save prunes files no longer referenced by that draft.
- `FacebookStorageService` reports post-thumbnail, draft-image and temp-upload
  usage, and sweeps unreferenced thumbnails, draft files/folders, and
  `oreamnos_fb_*` temp crops older than 24 hours.
- Settings → Facebook → **Storage** exposes the breakdown and **Clean up**.

## Pages + draft ownership (v12)

- `facebook_pages` stores `[{id,name,pictureUrl}]` (never tokens);
  `facebook_active_page` holds the active id.
- A user token is exchanged via `GET /me/accounts?fields=id,name,access_token,picture{url}`.
  Rows missing an id or token are skipped. Failures surface
  `pageTokenExchangeFailed` (or `expiredToken` for 190) without echoing the
  token.
- Legacy single-Page prefs migrate idempotently: the legacy token moves to
  `facebook_page_token_<id>` and the identity becomes the first Page entry.
- Every draft stores `pageId`/`pageName`. Switching Pages with a non-empty
  draft shows **Switch target / Duplicate draft / Keep original Page**.

## Draft model + migration

Each draft is a `FacebookDraftRecord` persisted in the `facebook_drafts` list
(cap 20, newest first) with an active id in `facebook_active_draft`. Images are
copied to `<appDocs>/facebook_drafts/<draftId>/<n>.<ext>` on every save, so OS
temp cleanup cannot break a draft. `pruneOrphans()` removes folders without a
record, and `pruneDraftMedia(id)` removes files no longer referenced by the
draft.

- Autosave is debounced (500 ms) and writes through the store.
- The back gesture offers **Save draft / Discard / Keep editing**; publishing
  or discarding deletes only that draft and its images.
- `facebook_compose_draft` (v9/v10 single draft) migrates into the store; the
  v9 `{text,imagePath,aspect}` shape is accepted.

## Write safety (v20)

- Publish/upload/schedule calls use `post<dynamic>` / `delete<dynamic>` and `_requireObject`, so a 200 HTML/plain/proxy body becomes `unexpectedResponse` instead of `network`.
- Photo uploads use the real extension/content type, validate non-empty/≤10 MB locally, and only skip re-encode for JPEG/PNG. Graph 400 bodies log code/subcode/user messages in debug builds.
- Timeouts: feed/multi-photo/schedule 60 s receive; photo upload 120 s send + receive.
- Graph writes carry `extra: {'graphWrite': true}`; `RetryInterceptor` never auto-retries them. Only GETs retry, avoiding duplicate posts when a response is lost.
- A transport/unexpected failure during a write enters `publishUncertain`: draft preserved, no history row, and the UI offers View Published / View Scheduled / Try again (duplicate warning) / Discard.
- The same `facebookRequireObject` guard applies to Page verification, insights and comments. Comment writes are `graphWrite` (no auto-retry) with 60 s windows; a non-JSON comments/insights 200 shows the unexpected-response message instead of a network error.

## Workflows + Page Stories (v16)
Workflows are reusable destination presets:

- Page post only
- Page post + Story
- Story only
- Custom (per Page or any Page), with an optional custom Story title

Storage: `facebook_workflows` (cap 10, no tokens) plus
`facebook_default_workflow_<pageId>`. The default applies when a draft starts;
composer changes are per-post unless the user taps **Make default**.

### Story Graph calls

| Step | Call |
|---|---|
| Upload unpublished Story photo | `POST /{page-id}/photos` (`source`, `published=false`) |
| Publish Story | `POST /{page-id}/photo_stories` (`photo_id`) |
| List Stories (optional) | `GET /{page-id}/stories` |

Constraints:

- Requires `pages_manage_posts`, `pages_read_engagement`, `pages_show_list` and
  `CREATE_CONTENT` on the Page.
- The Story photo cannot have been used in a previously published post, so the
  app always uploads a **dedicated** Story JPEG.
- The API has no Story caption field. `FacebookStoryTitle` extracts the
  headline/first line (max 100 chars) and `FacebookStoryComposer` bakes it into
  a **1080×1920** JPEG with a scrim and optional generated gradient background.
- Stories cannot be scheduled through this API.
- Feed failure aborts before the Story. Story failure after a successful feed is
  a partial success; `Retry Story` re-uploads/republishes only the Story.

## Crop cache (v15)

`FacebookImageCropper` skips re-encoding when zoom is 1, offset is zero and the
source aspect is within 0.5% of the target. Crop outputs are cached in memory
(keyed by source + aspect + zoom + offset + quality, max 20) so retries reuse
the encoded file.

## Crop math

`FacebookImageCropper.cropRectFor` is the single source of truth:

1. Build the centered base rect for the target aspect.
2. Shrink it by `1 / zoom`.
3. Translate by `offset × maxDx/maxDy`, where
   `maxD = baseSize × (1 − 1/zoom) / 2`.
4. Clamp the rect inside the source.

The composer preview uses the same values (scale + translate, clamped pan), so
the upload matches what the user sees. Panning is disabled at `zoom == 1`.

Encoding: decode → bake orientation → crop → resize longest edge to 2048 px →
JPEG quality 85, on a background isolate via `image`. If that fails, a `dart:ui`
PNG crop is used. The output filename extension reflects the real format.

## Graph calls (v23.0)

| Action | Call |
|---|---|
| Verify token / Page | `GET /me?fields=id,name,picture{url}` |
| List Pages (user token) | `GET /me/accounts?fields=id,name,access_token,picture{url}&limit=100` |
| Text post | `POST /{page-id}/feed` (`message`) |
| Photo post | `POST /{page-id}/photos` (`message`, `source`, `alt_text_custom`) |
| Unpublished photo | `POST /{page-id}/photos` (`published=false`, `source`, `alt_text_custom`) |
| Multi-photo post | `POST /{page-id}/feed` (`message`, `attached_media[]`, JSON) |
| Schedule | add `published=false` + `scheduled_publish_time` (Unix seconds, UTC) |
| List scheduled | `GET /{page-id}/scheduled_posts?fields=id,message,scheduled_publish_time` |
| Cancel / delete | `DELETE /{post-id}` with token in the body |
| Edit caption | `POST /{post-id}` (`message`) |
| Reschedule | `POST /{post-id}` with `scheduled_publish_time` |
| Insights | `GET /{post-id}?fields=insights.metric(post_total_media_view_unique,post_reactions_by_type_total,post_activity_by_action_type)` |
| Engagement | `GET /{post-id}?fields=reactions.summary(true),comments.summary(true),shares` |
| Page performance | `GET /{page-id}/insights?metric=page_media_view,page_follows,page_post_engagements&period=day&since=…&until=…` |
| Estimated earnings | `GET /{page-id}/insights?metric=content_monetization_earnings,monetization_approximate_earnings` |
| List comments | `GET /{post-id}/comments?fields=…&limit=25&after=<cursor>` |
| Reply to comment | `POST /{comment-id}/comments` (`message`) |
| Hide comment | `POST /{comment-id}` (`is_hidden`) |
| Delete comment | `DELETE /{comment-id}` |
| Upload Story photo | `POST /{page-id}/photos` (`published=false`) |
| Publish Story | `POST /{page-id}/photo_stories` (`photo_id`) |
| List Stories | `GET /{page-id}/stories` |
| Delete unpublished photo | `DELETE /{photo-id}` with token in the body |

Scheduled posts return no permalink; the record keeps the Graph id and the
success view shows the due time instead of a link.

## Timezone

- UI and drafts use device-local time.
- Persisted timestamps are UTC ISO-8601.
- Graph receives UTC seconds.
- Scheduling limits: at least 10 minutes ahead, at most 30 days ahead. The Page
  timezone may differ from the device; the composer footnote says so.

## History

`FacebookPostRecord` stores `status` (`published | scheduled | failed`),
`scheduledAt`, `pageId`, `pageName`, `localImagePaths`, `errorMessage` and the
optional insights cache (`uniqueViewers`, `reactions`, `comments`, `shares`,
`impressions`/`clicks` for earlier cached records, `reactionsByType`,
`activityByActionType`, `insightsFetchedAt`, `engagementFetchedAt`). History is
capped at 50. Removing a record deletes its local thumbnails.

On opening history, the app best-effort fetches `/{page}/scheduled_posts`. A
local scheduled record whose time has passed and that is absent from Graph is
promoted to published (permalink rebuilt from the post id). Fetch failures leave
local state untouched.

Published rows render a compact stats line only when `hasInsights`; scheduled
rows never fetch insights. Long-press **Refresh insights** and pull-to-refresh
(sequential, capped at 10) update the cache.

## Error taxonomy

`FacebookApiException` maps Graph codes:

| Codes | Kind | UI |
|---|---|---|
| 190 | `expiredToken` | Reconnect your Page |
| 200, 10 | `permission` | Update token / Page roles |
| 4, 17, 32, 613 | `rateLimit` | Wait and retry |
| 506 | `duplicate` | Edit the caption |
| local upload failure | `mediaUploadFailed` | Retry the photos |
| insights missing | `insightsUnavailable` | Hide the stats line |
| Page insights/metrics changed | `insightsUnavailable` | Explain metric names may have changed |
| Page insights permission | `permission` | Reconnect with `read_insights` + ANALYZE |
| `/me/accounts` failure | `pageTokenExchangeFailed` | Check permissions/token |
| caption edit rejected | `unknown` | Delete and repost guidance |
| comment action denied | `permission` | Reconnect with `pages_manage_engagement` |
| Story unsupported | `storyUnavailable` | Feed still publishes; no retry loop |
| Story + schedule | `storySchedulingUnsupported` | Post now or remove Story |
| scheduling rejected | `schedulingNotAllowed` / `invalidScheduleTime` | Adjust time/token |
| transport | `network` | Check connection |
| other | `unknown` | Show Facebook's message |
