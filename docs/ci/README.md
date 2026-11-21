# Release workflow — parked

This is `.github/workflows/release.yml`, moved out of `.github/workflows/`
because Oreamnos currently releases **locally** (Route A in
[`RELEASING.md`](../../RELEASING.md)): the four signing secrets do not exist, so
every tag push produced a failing run that published nothing.

GitHub only runs files inside `.github/workflows/`, so nothing here can fire by
accident.

## Restoring it (Route B)

1. Add the four secrets (see "Route B" in `RELEASING.md`):
   `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`,
   `ANDROID_KEY_PASSWORD`, `ANDROID_KEY_ALIAS`.
2. Move the file back:

   ```bash
   git mv docs/ci/release-workflow.yml.disabled .github/workflows/release.yml
   git commit -m "ci: re-enable tag-driven release builds"
   git push
   ```

3. Publish with `scripts/release.sh <version>` (it refuses to run while the
   workflow is absent).

## Remember

- The `Release APK` workflow derives `versionCode` from the run number (~30),
  which is far above the `+N` values used by the local route. Mixing the two
  makes later local builds uninstallable, so pick one route and stay on it.
- Route A's helper is `scripts/release-local.ps1`.
