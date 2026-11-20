# Releasing Oreamnos

Releases are built and published by GitHub Actions. A pushed tag is the only
thing that starts a release — there is no manual upload step.

```
tag  →  .github/workflows/release.yml  →  signed APK + .sha256 on the Releases page
```

## One-time setup (human, do this once)

The app is already signed locally with `android/app/upload-keystore.jks`. **Use
that key.** Do not generate a new keystore: Android refuses to install an APK
signed with a different key over an existing install, so every user would have
to uninstall first.

1. Base64-encode the existing keystore and keep the output out of git:

   ```bash
   # macOS / Linux / Git Bash
   base64 -w0 android/app/upload-keystore.jks > keystore.b64
   ```

   ```powershell
   # Windows PowerShell
   [Convert]::ToBase64String([IO.File]::ReadAllBytes("android/app/upload-keystore.jks")) |
     Out-File keystore.b64 -Encoding ascii
   ```

   `*.b64` is git-ignored.

2. Add the four repository secrets. Use the alias and passwords that are
   already in your local `android/key.properties` — copy them by hand, never
   commit or paste them into an issue:

   ```bash
   gh secret set ANDROID_KEYSTORE_BASE64 < keystore.b64
   gh secret set ANDROID_KEYSTORE_PASSWORD
   gh secret set ANDROID_KEY_PASSWORD
   gh secret set ANDROID_KEY_ALIAS
   ```

3. Delete `keystore.b64`.

4. Back the keystore up offline in two places. **If you lose it, installed
   users can never update in place again.**

### Optional: `BUILD_NUMBER_OFFSET`

`versionCode` comes from the workflow's `GITHUB_RUN_NUMBER` plus this repository
variable. Android will not install an APK whose `versionCode` is lower than the
installed one. Only set it if a device already has a build with a higher code
than CI produced, e.g. `gh variable set BUILD_NUMBER_OFFSET --body 1000`.

## Making a release

```bash
git switch main
git pull
scripts/release.sh 1.2.0
```

The script checks that the tree is clean and the tag is free, bumps the cosmetic
`version:` line in `pubspec.yaml`, commits it, creates the annotated tag, and
pushes both.

CI then:

1. validates the tag, derives `versionName` (the tag) and `versionCode` (the run
   number + offset);
2. restores the keystore from secrets;
3. runs `dart format --set-exit-if-changed`, `flutter analyze`, `flutter test`;
4. builds one **universal** release APK;
5. fails if the APK is signed with the debug key;
6. publishes the APK plus a `.sha256` and auto-generated release notes.

Tags with a hyphen (`v1.3.0-beta.1`) are published as **pre-releases**. GitHub's
`/releases/latest` endpoint ignores those, so a test build never prompts users to
update.

## Doing a test release

```bash
scripts/release.sh 0.0.1-test.1
```

Then confirm:

- the workflow is green and a release appears marked **Pre-release**;
- both the `.apk` and `.apk.sha256` assets are attached;
- the workflow summary shows a certificate that matches your local release
  builds (`apksigner verify --print-certs` on a local APK);
- installing it over an older build upgrades in place.

Delete the test release when done:

```bash
gh release delete v0.0.1-test.1 --cleanup-tag -y
```

## Removing a bad release

```bash
gh release delete v1.2.0 --cleanup-tag -y
git push origin :refs/tags/v1.2.0   # if cleanup-tag did not remove it
```

Fix the problem, then tag a higher version. Never re-tag the same version with
different contents.

## How the in-app update check finds releases

The app calls `https://api.github.com/repos/NaimNajmios/oreamnosv2/releases/latest`
unauthenticated. That only works because the repository is public. No token is
shipped in the APK, so keep the repository public or the check will silently
return nothing.
