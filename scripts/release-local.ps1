<#
.SYNOPSIS
    Build and publish a release APK to GitHub Releases (manual Route A).

.DESCRIPTION
    One command replaces the four-step manual loop:

        bump pubspec version -> build signed APK -> stage + checksum -> publish release

    The in-app update check reads
    https://api.github.com/repos/<owner>/<repo>/releases/latest, so the tag,
    the asset name and the flags below all matter. This script enforces them.

    Run it from anywhere inside the repository.

.PARAMETER Version
    Release version name, e.g. 1.2.0. Plain semver only: a hyphenated version
    (1.2.0-beta.1) would be published as a pre-release and would be invisible
    to /releases/latest, so it is rejected.

.PARAMETER Notes
    Release notes shown in the app's update dialog (markdown supported).
    Defaults to "Release v<version>".

.PARAMETER SkipPush
    Build and publish without committing/pushing the pubspec version bump.

.PARAMETER DryRun
    Validate everything and print the plan, but change nothing.

.EXAMPLE
    .\scripts\release-local.ps1 1.2.0

.EXAMPLE
    .\scripts\release-local.ps1 1.2.0 -Notes "- Fixed the calendar tap.`n- Faster generation."

.EXAMPLE
    .\scripts\release-local.ps1 1.3.0 -DryRun
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Version,

    [string]$Notes = '',

    [switch]$SkipPush,

    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

# --- Configuration -----------------------------------------------------------
$Repo = 'NaimNajmios/oreamnosv2'
$Branch = 'main'
$DistDir = 'dist'

# --- Helpers -----------------------------------------------------------------
function Fail([string]$Message) {
    Write-Host ""
    Write-Host "x $Message" -ForegroundColor Red
    exit 1
}

function Step([string]$Message) {
    Write-Host "> $Message" -ForegroundColor Cyan
}

function Ok([string]$Message) {
    Write-Host "  $Message" -ForegroundColor DarkGray
}

function Find-Gh {
    $cmd = Get-Command gh -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $fallback = 'C:\Program Files\GitHub CLI\gh.exe'
    if (Test-Path $fallback) { return $fallback }
    Fail "GitHub CLI not found. Install it with: winget install --id GitHub.cli"
}

# Compares two MAJOR.MINOR.PATCH strings. Returns -1, 0 or 1.
function Compare-Version([string]$A, [string]$B) {
    $left = ($A -replace '^[vV]', '').Split('.')
    $right = ($B -replace '^[vV]', '').Split('.')
    $length = [Math]::Max($left.Count, $right.Count)
    for ($i = 0; $i -lt $length; $i++) {
        $x = if ($i -lt $left.Count) { [int]($left[$i] -replace '[^0-9]', '') } else { 0 }
        $y = if ($i -lt $right.Count) { [int]($right[$i] -replace '[^0-9]', '') } else { 0 }
        if ($x -ne $y) { return [Math]::Sign($x - $y) }
    }
    return 0
}

function Get-PubspecVersion {
    $line = Select-String -Path pubspec.yaml -Pattern '^version:\s*(.+)$' | Select-Object -First 1
    if (-not $line) { Fail "No version: line found in pubspec.yaml" }
    $raw = $line.Matches[0].Groups[1].Value.Trim()
    $name, $build = $raw.Split('+', 2)
    if (-not $build) { $build = '1' }
    return [pscustomobject]@{
        Raw   = $raw
        Name  = $name.Trim()
        Build = [int]($build -replace '[^0-9]', '')
    }
}

function Get-AndroidTool([string]$Name) {
    $sdks = @(
        $env:ANDROID_HOME,
        $env:ANDROID_SDK_ROOT,
        (Join-Path $env:LOCALAPPDATA 'Android\Sdk')
    ) | Where-Object { $_ -and (Test-Path $_) }

    foreach ($sdk in $sdks) {
        $tool = Get-ChildItem -Path (Join-Path $sdk 'build-tools') -Directory -ErrorAction SilentlyContinue |
            Sort-Object { [version]($_.Name -replace '[^0-9.]', '') } |
            ForEach-Object { Join-Path $_.FullName $Name } |
            Where-Object { Test-Path $_ } |
            Select-Object -Last 1
        if ($tool) { return $tool }
    }
    return $null
}

# --- Preconditions -----------------------------------------------------------
$repoRoot = git rev-parse --show-toplevel 2>$null
if (-not $repoRoot) { Fail "Not inside a git repository." }
Set-Location $repoRoot

$current = Get-PubspecVersion
$newBuild = $current.Build + 1
$tag = "v$Version"

if ($Version -notmatch '^\d+\.\d+\.\d+$') {
    Fail "Version must look like 1.2.0 (no hyphen). A pre-release tag is ignored by /releases/latest, so the app would never see it."
}

$gh = Find-Gh

$auth = & $gh auth status 2>&1
if ($LASTEXITCODE -ne 0) {
    Fail "GitHub CLI is not authenticated. Run: gh auth login"
}

# Release must be newer than what is published, otherwise the app stays silent.
$latestTag = $null
$previous = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
try {
    $latestTag = (& $gh release list --repo $Repo --limit 1 --json tagName --jq '.[0].tagName' 2>$null)
    if ($LASTEXITCODE -ne 0) { $latestTag = $null }
} catch {
    $latestTag = $null
} finally {
    $ErrorActionPreference = $previous
}
$latestTag = "$latestTag".Trim()
if ($latestTag -eq 'null') { $latestTag = $null }

if ($latestTag) {
    $latestVersion = $latestTag -replace '^[vV]', ''
    if ((Compare-Version $Version $latestVersion) -le 0) {
        Fail "Published release is $latestTag; $Version is not newer, so the in-app check would never prompt. Pick a higher version."
    }
    Ok "Latest published: $latestTag"
} else {
    Ok "No published release yet."
}

# Tag must be free.
$existingTag = (git ls-remote --tags origin "refs/tags/$tag")
if ($existingTag) {
    Fail "Tag $tag already exists. Never re-tag a published version; bump the version instead."
}

if (-not $Notes) { $Notes = "Release $tag" }

$dirty = git status --porcelain
if ($dirty -and -not $DryRun -and -not $SkipPush) {
    Fail "Working tree is not clean. Commit or stash first (or pass -SkipPush to leave the bump uncommitted)."
}

$currentBranch = git rev-parse --abbrev-ref HEAD
if ($currentBranch -ne $Branch) {
    Write-Host "  warning: on branch '$currentBranch', the release will target '$Branch'." -ForegroundColor Yellow
}

# --- Plan --------------------------------------------------------------------
Write-Host ""
Ok "version:  $($current.Name)+$($current.Build)  ->  $Version+$newBuild"
Ok "tag:      $tag  (target $Branch)"
Ok "asset:    $DistDir/oreamnos-$tag.apk"
Ok "notes:    $($Notes.Substring(0, [Math]::Min(60, $Notes.Length)))"

if ($DryRun) {
    Write-Host ""
    Write-Host "Dry run: nothing was built, committed or published." -ForegroundColor Yellow
    exit 0
}

# --- 1. Bump the version ------------------------------------------------------
Step "Bumping pubspec.yaml to $Version+$newBuild"
(Get-Content pubspec.yaml -Raw) -replace '(?m)^version:[^\r\n]*', "version: $Version+$newBuild" |
    Set-Content pubspec.yaml -NoNewline

# --- 2. Build ----------------------------------------------------------------
Step "Building the release APK (this takes a few minutes)"
flutter build apk --release
if ($LASTEXITCODE -ne 0) { Fail "flutter build apk failed." }

$builtApk = 'build\app\outputs\flutter-apk\app-release.apk'
if (-not (Test-Path $builtApk)) { Fail "Expected $builtApk to exist." }

# --- 3. Verify what we are about to publish ----------------------------------
$apksigner = Get-AndroidTool 'apksigner.bat'
$aapt2 = Get-AndroidTool 'aapt2.exe'

if ($aapt2) {
    $badging = (& $aapt2 dump badging $builtApk 2>&1) -join "`n"
    if ($badging -match "versionName='([^']+)'") { $apkName = $Matches[1] }
    if ($badging -match "versionCode='([^']+)'") { $apkCode = [int]$Matches[1] }
    Ok "APK reports versionName=$apkName versionCode=$apkCode"
    if ($apkName -ne $Version) { Fail "APK versionName '$apkName' does not match '$Version'." }
    if ($apkCode -ne $newBuild) { Fail "APK versionCode '$apkCode' does not match '$newBuild'." }
} else {
    Write-Host "  warning: aapt2 not found, skipping versionName/versionCode verification." -ForegroundColor Yellow
}

if ($apksigner) {
    $certs = (& $apksigner verify --print-certs $builtApk 2>&1) -join "`n"
    if ($certs -match 'Android Debug') {
        Fail "APK is signed with the debug key. Check android/key.properties and android/app/upload-keystore.jks."
    }
    if ($certs -match 'SHA-256 digest:\s*([0-9a-f]+)') {
        Ok "Signed with SHA-256 $($Matches[1])"
    } else {
        Ok "Signature present (not debug)."
    }
} else {
    Write-Host "  warning: apksigner not found, skipping signature check." -ForegroundColor Yellow
}

# --- 4. Stage the assets -----------------------------------------------------
Step "Staging release assets"
New-Item -ItemType Directory -Force -Path $DistDir | Out-Null
$apkPath = Join-Path $DistDir "oreamnos-$tag.apk"
$sumPath = "$apkPath.sha256"

Copy-Item $builtApk $apkPath -Force
$hash = (Get-FileHash $apkPath -Algorithm SHA256).Hash.ToLower()
"$hash  oreamnos-$tag.apk" | Out-File -Encoding ascii $sumPath
Ok "$apkPath ($([Math]::Round((Get-Item $apkPath).Length / 1MB, 1)) MB)"
Ok "sha256 $hash"

# --- 5. Commit + push the bump -----------------------------------------------
if (-not $SkipPush) {
    Step "Committing the version bump"
    git add pubspec.yaml
    git commit -m "chore(release): $tag" --quiet
    if ($LASTEXITCODE -ne 0) { Fail "git commit failed." }

    Step "Pushing $Branch"
    git push origin $Branch
    if ($LASTEXITCODE -ne 0) { Fail "git push failed. The release was NOT published (assets are in $DistDir)." }
}

# --- 6. Publish --------------------------------------------------------------
Step "Publishing $tag"
& $gh release create $tag $apkPath $sumPath `
    --repo $Repo `
    --target $Branch `
    --title $tag `
    --notes $Notes
if ($LASTEXITCODE -ne 0) { Fail "gh release create failed. Assets are still in $DistDir." }

# --- 7. Verify what the app will see -----------------------------------------
Step "Verifying the published release"
$releaseJson = & $gh api "repos/$Repo/releases/latest" 2>$null
if ($LASTEXITCODE -ne 0) { Fail "Could not read /releases/latest." }
$published = $releaseJson | ConvertFrom-Json
if ($published.tag_name -ne $tag) {
    Fail "latest release is '$($published.tag_name)', expected '$tag'. Something was published out of order."
}
if ($published.prerelease -or $published.draft) {
    Fail "Release is a draft or pre-release; the app would ignore it."
}

$apkAsset = $published.assets | Where-Object { $_.name.ToLower().EndsWith('.apk') } | Select-Object -First 1
if (-not $apkAsset) { Fail "No .apk asset on the release; the app would ignore it." }

Write-Host ""
Write-Host "Published $tag" -ForegroundColor Green
Write-Host "  page:  $($published.html_url)"
Write-Host "  apk:   $($apkAsset.name) ($($apkAsset.size) bytes)"
Write-Host "  check: https://api.github.com/repos/$Repo/releases/latest -> $($published.tag_name)"
Write-Host ""
Write-Host "The app will offer this update once its installed version is lower." -ForegroundColor DarkGray
