# Design System — Threads Convergence

> `lib/config/theme/` source of truth. All values below are live from code.

## Tokens

**Spacing** `lib/config/theme/app_spacing.dart:4`

```
xs 4 · sm 8 · md 12 · base 16 · lg 20 · xl 24 · xxl 32 · xxxl 40 · huge 48
screenHorizontal 20 · maxContentWidth 640
radiusXs 4 · radiusSm 8 · radiusMd 12 · radiusLg 16 · radiusXl 24 · radiusPill 999
```

**Colors** `lib/config/theme/app_colors.dart:1`

* Accent Threads blue `lightAccent 0095F6:13` (never Neo `#FF4500` — `grep FF4500 0`).
* Surfaces: `lightBg FFFFFFFF` / `lightSurface F5F5F5` / `darkBg 000000` / `darkSurface 1A1A1A`; borders `lightBorder E5E5E5` / `darkBorder 2E2E2E`.
* Per-provider tints `AppColors.tintForProvider:58` / `softForProvider:67` (`gemini accent/soft, groq emerald, openRouter amber, cerebras violet, fallback teal`).

**Typography** `lib/config/theme/app_typography.dart:1` — system sans (Roboto/SF Pro via `ThemeData.useMaterial3`), `GoogleFonts.inter/lora/spaceMono` only for card canvas `lib/ui/features/card_generator/widgets/card_canvas.dart:38`, `mono()` helper `146` for `11` usage.

**Palette vs Code:** `freezed` helpers `StatItem/ComparisonStat/LineupPlayer/TableRow/InjuryItem/ContractPlayer/NomineeItem` `lib/domain/models/card_data.dart:8-101`.

## Themes (9 modes kept, horizontally scrollable)

`lib/domain/models/app_theme_mode.dart:2` `enum AppThemeMode { light, dark, deepBlue, midnightNoir, solarizedLight, cyberpunk, matchday, forest, system }`

`lib/config/theme/app_theme.dart:8` 8 palettes + `system` (DynamicColor follows OS `ColorScheme` `lib/app.dart:80`).

| Mode | Preview `lib/ui/features/settings/views/settings_screen.dart:62` |
|---|---|
| light | `grey300` |
| dark | `grey900` |
| deepBlue | `0xFF1E3A8A` |
| midnightNoir | `0xFF171717` |
| solarizedLight | `0xFFFDF6E3` |
| cyberpunk | `0xFFFF003C` |
| matchday | `0xFFDC2626` |
| forest | `0xFF2E7D32` |
| system | `theme.colorScheme.primary` |

**Picker:** `lib/ui/features/settings/views/settings_screen.dart:55` `SingleChildScrollView(horizontal, clipBehavior none)` + `Row` + `SizedBox(md 12)` separators, circles `48×48:102` with `check_rounded + luminance` `118`, labels `labelSmall`. Replaced `Wrap(spacing md, runSpacing md):55` which wrapped to 2 rows (~144px) → single row (~66px).

**Selection:** `border 2 primary :110` when selected else `outline 0.3 1 :112`; `onTap Haptics.lightImpact:96 → viewModel.setThemeMode`.

`lib/app.dart:80` `DynamicColorBuilder(lightDynamic, darkDynamic) → switch(themeMode)` 9 cases `86-124` (`light/dark/deepBlue/.../forest/system`).

## Components (25/26 Threads, 1 residual fixed)

| Widget | Radius / Tokens | State |
|---|---|---|
| `AppCard` `lib/ui/core/widgets/app_card.dart:5` | `radiusLg 16` + `cardTheme elevation 1:210` + `side none:213` | Threads — soft surface, no border |
| `AppButton` `lib/ui/core/widgets/app_button.dart:7` | `pillXl 24` + `scale 0.98` | Threads |
| `AppChip` `lib/ui/core/widgets/app_chip.dart:6` | `pillXl + border 1` | Threads pill |
| `AppInput` `lib/ui/core/widgets/app_input.dart:75` | `filled surface 12dp focus 1.5 blue` | Threads |
| `RefinementPill` `lib/ui/core/widgets/refinement_pill.dart:42` | `pill` | Threads |
| `SkeletonLoader` `lib/ui/core/widgets/skeleton_loader.dart:5` | `1200ms 0.3→0.7 + shouldReduceMotion:117` | Threads (not spinner; `grep CircularProgress 0`) |
| `SettingsTile` `lib/ui/core/widgets/settings_tile.dart:5` | `borderRadiusSm` + `chevron_right_rounded 71 onSurfaceVariant` | Fixed from `brutalist + BorderRadius.zero:35 + arrow_forward` |
| `FAB` `lib/ui/features/settings/views/hashtag_manager_screen.dart:186` `pill_manager_screen.dart:125` | `elevation 1` | Fixed from `2` |
| `NavigationBar` `lib/ui/features/shell/views/modern_app_shell.dart:52` | `height 60 indicator transparent icon 26 labelSmall 500/600` `app_theme.dart:295` | Threads compact 4-tab |

Remaining `Serene`/`Sciuro` docstring branding in comments is visual-noop; `FAB` now `1` matches `subtleShadow alpha 0.05:50`.

## Screens

* **Generate** `lib/ui/features/generate/views/generate_screen.dart:1` — `ConstrainedBox 640` `screenHorizontal 20`, `SegmentedButton` length `Short/Medium/Long`, `AppInput` hint, `LinkPreviewCard`, `Scan Image` pill `surfaceContainerHighest 0.8`, `SkeletonLoader.outputCard:678` during `generating`, `SwipeableOutputCard` + `AppChip Title/Hashtags/Source`, `RefinementPill` row.
* **Cards** `lib/ui/features/card_generator/views/card_generator_screen.dart:1` — `CardStage` + `CardCanvasDispatcher` 17 variants (16 + `SparseCard` fallback `dispatcher:52`).
* **Settings** — Appearance horizontal scroll above + `SectionHeader` + `SettingsTile` rows + `Divider hairline`.
* **Usage** `lib/ui/features/usage/views/usage_screen.dart:1` — `StatCard` 3× (`Tokens/Success/Latency` `mono 11`), `UsageChart` `CustomPaint 180px` per-provider hue `AppColors.tintForProvider`.

## Motion

`lib/config/theme/app_motion.dart:1` `micro 120`/`transition 280`/`celebration 600` + `colorTransition 200` `lib/config/constants.dart:34`. Used in `AnimatedSwitcher 220 easeOutCubic` `generate_screen.dart:293`.

## Next Doc

* Remove `http` from `pubspec.yaml:25` after probes `test_scraper.dart` move to `tool/`; clarify `dio` is pooled source.
