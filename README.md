# Oreamnos

**Oreamnos** is an AI-assisted editorial curator and social card generator built with Flutter. It streamlines the workflow of curating, polishing, and designing sports media content (specifically football/soccer) across multiple LLM providers (**Gemini**, **Groq**, **OpenRouter**, **Cerebras**) with rich Malay editorial styling, on-device OCR, and instant shareable canvas generation.

---

## Key Features

### 1. Multi-Provider AI Content Generation
- **Supported Providers**: Google Gemini, Groq, OpenRouter, Cerebras.
- **Dynamic Model Discovery**: Fetches compatible models on the fly per API key.
- **Resilient Network Layer**: Powered by `ApiClient` (Dio connection pooling, auth injection, exponential backoff retries with jitter, and HTTP error mapping to sealed domain `Failure`s).
- **Background Isolate Parsing**: Complex JSON cleanups and extractions run in Dart worker isolates via `JsonCleaner.decodeIsolate`.

### 2. Multi-Variant Card Generator (16 Templates + Sparse Fallback → 17 Renderers)
Instant, pixel-perfect 1:1 and story graphics with deterministic JSON schema extraction and customized canvas renderers (`CardCanvasDispatcher` `lib/ui/features/card_generator/widgets/renderers/card_canvas_dispatcher.dart:33` dispatches 17: 16 + `SparseCard` fallback):
- **Player Spotlight**: Prominent name, club/position badge, star rating, goals/assists/appearances pills, and key action callout.
- **Headline Quote**: Editorial quote typography with quotation styling, author byline, and title badge.
- **Top Stats**: 2x2 numeric metric cards with context labels.
- **Transfer News**: `TRANSFER ALERT` badge, From $\rightarrow$ To transfer route cards, fee & contract duration badges.
- **Breaking News**: High-impact red alert banner, bold typography, and team tags.
- **Match Preview**: Home vs Away matchup cards, form comparison pills, venue & kickoff schedule.
- **Detailed Scoreboard**: Full-time/live match status banner, big score display (`3 - 1`), scorers list, possession & shots metrics.
- **On This Day**: Historic calendar badge, `X YEARS AGO` banner, and retrospective narrative.
- **Starting XI**: Tactical formation badge (e.g. `4-3-3`), manager label, and two-column lineup grid with jersey numbers.
- **Match Stats Comparison**: Proportion comparison bars with dual-color balance.
- **Social Post**: Verified badge, social handle, avatar, post content, and engagement metrics.
- **Head-to-Head Rivalry**: Split comparison layout for player/team rivalries.
- **Table Standings**: League table ranking (`POS`, `TEAM`, `PL`, `GD`, `PTS`) with highlighted club accent row.
- **Injury Report**: Medical cross badge, squad fitness list with recovery progress.
- **Contract Expiry**: Countdown badge, player list with position, market value, and expiry year.
- **Award Nominees**: Trophy badge, award category, nominees with `FAV` tag and odds.
- **Sparse Fallback**: Graceful fallback renderer for unstructured outputs.
- **Design Customization**: Palette auto-extraction via `ColorExtractor` (200px thumbnail optimization), manual gradient picking, font size multiplier, and scrim overlay adjustments.
- **High-Res Export**: Direct gallery saving (`gal`) and native sharing (`share_plus`) via `RepaintBoundary`.

### 3. Vision Extraction (On-Device OCR)
- Privacy-first text recognition using `google_mlkit_text_recognition`.
- Direct Gallery image picker integration on the Generate screen to extract text from screenshots, match graphics, and infographics.

### 4. Reading Mode & Customization
- Immersive, distraction-free reading screen with dynamic font sizing (Small, Medium, Large, Extra Large).
- Drag-down to dismiss modal sheet gesture.
- 9 themes via `AppThemeMode` (`lib/domain/models/app_theme_mode.dart:2`): **Light**, **Dark**, **Deep Blue**, **Midnight Noir**, **Solarized Light**, **Cyberpunk**, **Matchday**, **Forest**, **System** (follows OS `ColorScheme` via `DynamicColorBuilder` `lib/app.dart:80`); picker is horizontally scrollable `SingleChildScrollView` `lib/ui/features/settings/views/settings_screen.dart:55`.

### 5. Delight & Micro-Interactions
- **`EnhancedLoadingCard`**: 0–95% progress indicator with pulse breathing scale and 3-step stage dots.
- **`SuccessOverlay`**: First-time completion celebration featuring a 25-particle radial explosion and animated checkmark path.
- **`InputClearButton`**: 2-step confirmation (`Clear` $\rightarrow$ `Confirm?` with 3-second auto-reset timer) and haptic feedback.
- **`LinkPreviewCard`**: Immediate domain extraction badge with quick action button.
- **`SwipeableOutputCard`**: Swipe-to-copy / swipe-to-share gestures with an introductory 800ms shimmy nudge.

### 6. Analytics & Debugging
- **`LogService`**: In-memory ring buffer (200 entries) with debounced 500ms disk persistence and microtask notifications.
- **`DebugLogScreen`**: Filterable logs with text search, level chips (`DEBUG`, `INFO`, `WARN`, `ERROR`), tag chips, and details modal.
- **`UsageService`**: Historical token and latency tracking with provider success rate calculations (`getSuccessRateByProvider`) and filter chips.

---

## Architecture & Tech Stack

```
lib/
├── app.dart                   # Root ConsumerStatefulWidget + DynamicColorBuilder (9 themes) + GoRouter
├── main.dart                  # configureDependencies() → ProviderScope + Notification/QuickSettings init
├── config/
│   ├── routes/                # GoRouter 4 Shell tabs (/generate, /card-generator, /usage, /settings) + 5 full-screen
│   └── theme/                 # AppTheme (8 palettes + system), AppColors (0095F6), AppSpacing (radiusMd 12/Lg 16), AppTypography, AppMotion
├── core/
│   ├── di/                    # injection.dart / injection.config.dart / register_module.dart (get_it + injectable)
│   ├── error/                 # failures.dart sealed Result<T>/Failure (dead — next phase)
│   ├── network/               # ApiClient pooled Dio (4 interceptors: Auth, ErrorMapping, Retry, Logging)
│   └── repositories/          # IContentRepository/ICardRepository/IUsageRepository/ISettingsRepository (defined, bypassed)
├── data/
│   ├── models/                # AiProvider 4 + nextFallback chain
│   └── services/              # Curators (Gemini/OpenAICompat via ApiClient), CardDataExtractor (template-aware), WebScraperService/ProviderApiService (dio), Preferences/Usage/Log/MLKit/Export
├── domain/
│   ├── models/                # CardData sealed 17 (16 + Sparse), CardTemplate 16, CardConfig, CuratedPost, AppThemeMode 9, UsageLog
│   └── services/              # IContentCurator, IVisionExtractor, CardPromptManager (16 schemas) / GenerationPromptManager, JsonCleaner
└── ui/
    ├── core/                  # AppCard 16dp / AppButton pillXl / AppChip pill / AppInput 12dp + SkeletonLoader + SuccessOverlay 25 particles + RateLimitDialog
    └── features/              # generate (SwipeableOutputCard + RateLimit fallback) / card_generator (CardCanvasDispatcher) / settings (horizontal theme picker) / usage / shell (ModernAppShell)
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

# Run complete test suite (75 tests) with coverage
flutter test --coverage

# Run build runner for codegen (Freezed & json_serializable & injectable)
dart run build_runner build --delete-conflicting-outputs
```

---

## Testing & Quality Assurance

- **Unit & Widget Tests**: Comprehensive test suites in `test/unit/` covering `UsageService`, `LogService`, `GeminiCurator`, `OpenAICompatibleCurator`, `WebScraperService`, `DelightWidgets`, `CardDataExtractor`, `CardCanvasDispatcher` (all 17 variants), `JsonCleaner`, and network interceptors (`interceptors_test` asserts `429→RateLimitFailure`).
- **Continuous Integration**: Automated GitHub Actions workflow (`.github/workflows/ci.yaml` pinned `3.47.1` stable) verifying 4 gates — `dart format --output=none --set-exit-if-changed .` → `flutter analyze` (0) → `flutter test --coverage` → `dart run build_runner build` — on `push: [main,master]` and `pull_request: [main,master]`.

See `docs/architecture.md`, `docs/design-system-threads.md`, `docs/migration-threads-convergence.md`, `docs/baseline-phaseB.md`, and `CHANGELOG.md` for v2 Threads Convergence details.
