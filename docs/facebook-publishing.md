# Facebook Publishing

State machine, Graph calls, timezone rules, token storage, media lifecycle and
error taxonomy for the Facebook feature. Release v10 (photo pipeline + scheduling).

## Security contract

- The Page token lives only in `flutter_secure_storage` (`facebook_page_token`)
  and is only ever sent in a form body or an `Authorization: Bearer` header.
- Never put the token in a URL query, a log, analytics, prefs, or draft JSON.
- Drafts and history store local file paths only.
- `disconnectFacebook()` wipes the token, Page identity, history and the
  autosaved draft.

## State machine

```
editing → compressing → uploading → publishing → published
        ↘ scheduling → scheduled
        ↘ publishError (retryable | needsReconnect)
```

- `FacebookComposePhase` is `editing | publishing | published | scheduled |
  publishError`.
- `FacebookPublishMode { now, scheduled }` lives on the draft and is autosaved.
- `published` is terminal for the current draft (`canPublish == false`), which
  prevents duplicate posts and duplicate history rows.

## Draft model + migration

`FacebookComposeState.media` is a `List<FacebookMediaItem>` even though the v10
composer allows one photo, so the multi-photo phase needs no state migration.
Each item stores `path`, `aspect`, `zoom` (1–4), normalized `offset` (−1..1) and
`altText`.

Autosave writes `{text, media[], mode, scheduledAt}` (UTC ISO-8601) to
`facebook_compose_draft`. The parser also accepts the v9 shape
`{text, imagePath, aspect}` and migrates it to a single media item.

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
| Text post | `POST /{page-id}/feed` (`message`) |
| Photo post | `POST /{page-id}/photos` (`message`, `source`, `alt_text_custom`) |
| Schedule | add `published=false` + `scheduled_publish_time` (Unix seconds, UTC) |
| List scheduled | `GET /{page-id}/scheduled_posts?fields=id,message,scheduled_publish_time` |
| Cancel | `DELETE /{post-id}` with token in the body |
| Reschedule | `POST /{post-id}` with `scheduled_publish_time` |

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
`scheduledAt`, `pageId`, `pageName`, `localImagePaths`, and `errorMessage`.
History is capped at 50. Removing a record deletes its local thumbnails.

On opening history, the app best-effort fetches `/{page}/scheduled_posts`. A
local scheduled record whose time has passed and that is absent from Graph is
promoted to published (permalink rebuilt from the post id). Fetch failures leave
local state untouched.

## Error taxonomy

`FacebookApiException` maps Graph codes:

| Codes | Kind | UI |
|---|---|---|
| 190 | `expiredToken` | Reconnect your Page |
| 200, 10 | `permission` | Update token / Page roles |
| 4, 17, 32, 613 | `rateLimit` | Wait and retry |
| 506 | `duplicate` | Edit the caption |
| transport | `network` | Check connection |
| other | `unknown` | Show Facebook's message |
