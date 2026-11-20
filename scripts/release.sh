#!/usr/bin/env bash
# Tag a release. The pushed tag is what triggers .github/workflows/release.yml.
#
#   scripts/release.sh 1.2.0
#   scripts/release.sh 1.3.0-beta.1     # hyphen => GitHub pre-release
#
# Requires a clean working tree and push access to origin.
set -euo pipefail

VERSION="${1:?Usage: scripts/release.sh X.Y.Z[-prerelease]}"
if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$ ]]; then
  echo "Invalid version: $VERSION (expected X.Y.Z or X.Y.Z-prerelease)"
  exit 1
fi

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Working tree is not clean. Commit or stash first."
  exit 1
fi

BRANCH="$(git rev-parse --abbrev-ref HEAD)"
if [ "$BRANCH" = "HEAD" ]; then
  echo "Refusing to tag a detached HEAD."
  exit 1
fi

git fetch origin --tags

if git rev-parse -q --verify "refs/tags/v$VERSION" >/dev/null; then
  echo "Tag v$VERSION already exists."
  exit 1
fi

# Cosmetic only: CI overrides both values at build time. Keeping pubspec.yaml in
# step means a local `flutter run` reports the same version as the release.
sed -i.bak -E "s/^version: .*/version: ${VERSION}+1/" pubspec.yaml
rm -f pubspec.yaml.bak
git add pubspec.yaml
if ! git diff --cached --quiet; then
  git commit -m "chore(release): v${VERSION}"
fi

git tag -a "v${VERSION}" -m "Release v${VERSION}"
git push origin "HEAD" "v${VERSION}"

echo
echo "Pushed v${VERSION}."
echo "Watch the build:  gh run watch"
echo "Release page:     https://github.com/NaimNajmios/oreamnosv2/releases/tag/v${VERSION}"
