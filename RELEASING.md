# Releasing Oreamnos

The app updates itself from **GitHub Releases**: it reads
`https://api.github.com/repos/NaimNajmios/oreamnosv2/releases/latest` and offers
whatever `.apk` is attached there, when that tag is newer than the installed
version.

There are two ways to publish that release. **Route A is the default** and
needs no CI setup. Route B (GitHub Actions) is optional.

| | Route A — local build (default) | Route B — GitHub Actions |
|---|---|---|
| Setup | none | 4 repository secrets |
| Cost | ~4 min per release on your machine | ~5 min in CI |
| Signing | your local `key.properties` | keystore restored from secrets |
| `versionCode` | you bump `+N` in `pubspec.yaml` | workflow run number + offset |
| Command | `scripts/release-local.ps1 1.2.0` | `scripts/release.sh 1.2.0` |

**Pick one route and stay on it.** Route B's `versionCode` comes from the
workflow run number (~30 right now). If you publish once through CI and then go
back to Route A with `+3`, Android will refuse to install the lower code.

The `Release APK` workflow is **parked** at
`docs/ci/release-workflow.yml.disabled` (GitHub only runs files inside
`.github/workflows/`), so pushing a tag publishes nothing. See Route B to
restore it.

---

## Route A — local build and upload (default)

### Prerequisites, once

- `flutter` on PATH.
- `gh` authenticated: `winget install --id GitHub.cli`, then `gh auth login`.
- `android/key.properties` + `android/app/upload-keystore.jks` present. These are
  git-ignored and already exist on this machine. **Do not generate a new
  keystore**: Android refuses to install an APK signed with a different key over
  an existing install, and every user would have to uninstall first.
- Back the keystore up offline in two places. **If you lose it, installed users
  can never update in place again.**

### Every release

```powershell
git switch main
git pull
.\scripts\release-local.ps1 1.2.0
```

That one command:

1. validates the version is plain semver and **newer than the published one**;
2. checks the tag is free and `gh` is authenticated;
3. bumps `pubspec.yaml` to `1.2.0+<previous build + 1>`;
4. runs `flutter build apk --release`;
5. verifies the APK's `versionName`/`versionCode` and **fails if it is
   debug-signed**;
6. copies it to `dist/oreamnos-v1.2.0.apk` and writes a `.sha256`
   (`dist/` is git-ignored);
7. commits and pushes the version bump;
8. publishes the GitHub release with both assets;
9. re-reads `/releases/latest` to confirm the app will see it.

Useful flags:

```powershell
.\scripts\release-local.ps1 1.3.0 -DryRun      # validate + print the plan, change nothing
.\scripts\release-local.ps1 1.3.0 -Notes "- Faster generation`n- Fixed calendar tap"
.\scripts\release-local.ps1 1.3.0 -SkipPush    # build + publish, leave the bump uncommitted
.\scripts\release-local.ps1 1.3.0 -NoPublish   # build, verify + stage only; no commit, push or release
```

`-NoPublish` is the safe way to test a build or to upload the APK by hand: it
still bumps `pubspec.yaml` (uncommitted), builds, verifies the version/signature
and writes `dist/oreamnos-v<tag>.apk`, then stops and prints the exact
`gh release create` line to publish it later.

### Doing it by hand (if the script is unavailable)

```powershell
# 1. pubspec.yaml: version: 1.2.0+3     (the +N must be higher than the installed one)
flutter build apk --release

# 2. stage
New-Item -ItemType Directory -Force dist | Out-Null
Copy-Item build\app\outputs\flutter-apk\app-release.apk dist\oreamnos-v1.2.0.apk
(Get-FileHash dist\oreamnos-v1.2.0.apk -Algorithm SHA256).Hash.ToLower() + "  oreamnos-v1.2.0.apk" |
  Out-File -Encoding ascii dist\oreamnos-v1.2.0.apk.sha256

# 3. publish
gh release create v1.2.0 dist\oreamnos-v1.2.0.apk dist\oreamnos-v1.2.0.apk.sha256 `
  --repo NaimNajmios/oreamnosv2 --target main --title "v1.2.0" --notes "What changed"
```

### Rules the update check enforces

| Rule | Why |
|---|---|
| Tag is `vX.Y.Z`, **no hyphen** | hyphenated tags are pre-releases, invisible to `/releases/latest` |
| Release is published, **not draft, not pre-release** | same endpoint ignores both |
| An asset name **ends in `.apk`** | `AppRelease` picks the first such asset |
| Tag is **newer** than the installed `versionName` | otherwise the app correctly says "up to date" |
| `versionCode` (`+N`) is **higher** than the installed one | Android refuses the downgrade |

---

## Route B — GitHub Actions (optional)

`.github/workflows/release.yml` builds and publishes on a pushed `v*` tag. It is
**parked** at `docs/ci/release-workflow.yml.disabled` because the signing secrets
do not exist; see `docs/ci/README.md` for why and how to bring it back.

### One-time setup

1. Base64-encode the existing keystore and keep the output out of git:

   ```powershell
   [Convert]::ToBase64String([IO.File]::ReadAllBytes("android/app/upload-keystore.jks")) |
     Out-File keystore.b64 -Encoding ascii
   ```

   `*.b64` is git-ignored.

2. Add the four repository secrets, copying the alias and passwords by hand from
   your local `android/key.properties` — never commit or paste them anywhere:

   ```bash
   gh secret set ANDROID_KEYSTORE_BASE64 < keystore.b64
   gh secret set ANDROID_KEYSTORE_PASSWORD
   gh secret set ANDROID_KEY_PASSWORD
   gh secret set ANDROID_KEY_ALIAS
   ```

3. Delete `keystore.b64`.

4. Restore and enable the workflow:

   ```bash
   git mv docs/ci/release-workflow.yml.disabled .github/workflows/release.yml
   git commit -m "ci: re-enable tag-driven release builds"
   git push
   ```

### Every release

```bash
git switch main
git pull
scripts/release.sh 1.2.0
```

The script checks the tree is clean and the tag is free, bumps the cosmetic
`version:` line in `pubspec.yaml`, commits it, creates the annotated tag, and
pushes both. CI then:

1. validates the tag, derives `versionName` (the tag) and `versionCode` (run
   number + `BUILD_NUMBER_OFFSET`);
2. restores the keystore from secrets, failing loudly if one is missing;
3. runs `dart format --set-exit-if-changed`, `flutter analyze`, `flutter test`;
4. builds one **universal** release APK;
5. fails if the APK is signed with the debug key, and prints the certificate in
   the job summary;
6. publishes the APK plus a `.sha256` and auto-generated release notes.

Do **not** also run `gh release create` for that tag — CI creates the release.

Tags with a hyphen are published as **pre-releases**, so they never reach users.

### Optional: `BUILD_NUMBER_OFFSET`

`versionCode` comes from the workflow's `GITHUB_RUN_NUMBER` plus this repository
variable. Only set it if a device already has a build with a higher code than CI
produced: `gh variable set BUILD_NUMBER_OFFSET --body 1000`.

---

## Removing a bad release

```bash
gh release delete v1.2.0 --cleanup-tag -y
git push origin :refs/tags/v1.2.0   # if cleanup-tag did not remove it
```

Fix the problem, then publish a higher version. Never re-tag the same version
with different contents — installed clients compare version names and would
never see it.

## How the in-app update check finds releases

The app calls `https://api.github.com/repos/NaimNajmios/oreamnosv2/releases/latest`
unauthenticated, with a 10-second timeout, and treats 404 as "nothing published"
and 403/429 as rate limiting. That only works because the repository is public.
No token is shipped in the APK, so keep the repository public or the check will
silently return nothing.

Checks are throttled to once every 6 hours and fail silently at launch; the
**Settings → About → Check for updates** row forces a check and reports errors.
"Skip this version" is stored per tag in `update_skipped_tag`.
