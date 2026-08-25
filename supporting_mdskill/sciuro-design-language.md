# Design Language Specification
## Extracted from Sciuro's `core-ui` module — for reuse in a new application

> Everything below is read directly from the real, current source (`core-ui/src/main/java/.../theme/` and `.../components/`), not from planning docs or memory — those had drifted from what's actually implemented. Framework-agnostic where the values themselves are the point (hex codes, type scale, spacing); Compose-specific where the *pattern* is the point (the Hero Panel, in particular, is worth reimplementing in spirit even outside Compose).

---

## 1. Design Philosophy

This is a **financial ledger's** visual language, not a generic app skin — every decision below reads as "does this help someone scan numbers accurately and calmly," not "does this look impressive." Two things carry that intent structurally, not decoratively:

1. **A single full-bleed colored panel at the top of every primary screen** (the Hero Panel, §5) — one big number, calm chrome around it. This is the signature element: the thing a person would recognize this app by even with the logo covered.
2. **Two typefaces with a strict division of labor** — a humanist sans for everything you *read*, a monospace for everything you *count*. Money gets tabular alignment; nothing else does.

Everything else in this document exists to serve those two decisions without competing with them.

---

## 2. Color System

### 2.1 Semantic signal colors (constant across every palette)

| Token | Light | Dark |
|---|---|---|
| `signalIncome` | `#3DAE5C` | `#56D87A` |
| `signalTransfer` | `#7C9CBF` | `#9AB8DB` |
| `signalWarning` | `#E8B84B` | `#E8B84B` |
| `signalDanger` | `#E3543D` | `#FF6B5E` |

These four never change meaning regardless of which brand palette is active — green always means money in, red always means danger/over-limit, blue-grey always means a transfer (deliberately desaturated so it doesn't compete with income/danger for attention). Keep this separation in a new app: semantic color and *brand* color are different systems, and letting a brand palette swap also change what "danger" looks like is how trust erodes.

### 2.2 Brand palettes — a selectable system, not one fixed identity

The real system isn't one palette, it's **six**, all built from the same eleven-token shape (primary/onPrimary, secondary/onSecondary, tertiary/onTertiary, background/onBackground, surface/onSurface, surfaceVariant/onSurfaceVariant), each with a light and dark variant, plus a seventh "Dynamic" option that defers to the OS's wallpaper-derived color (Android 12+ Material You). Container colors (`primaryContainer`, `tertiaryContainer`) are *derived*, not hand-picked — blended toward the surface color at 8% (light) or 15% (dark) opacity, with a contrast-checked fallback for the "on" color.

**Monochrome** (the default/reference identity):
```
Light: primary #000000 / onPrimary #FFFFFF / background #F7F7F5 / surface #FFFFFF
Dark:  primary #FFFFFF / onPrimary #1C1C1E / background #121316 / surface #1C1D21
```
Pure black-on-off-white in light mode, pure white-on-near-black in dark mode. No accent color at all in the base identity — the accent lives entirely in the semantic signal colors (§2.1). This is the "quiet ledger" mode.

**Amber** (warm, terracotta-adjacent):
```
Light: primary #D97757 / background #FDF8F2 / surface #FFFBF9
Dark:  primary #E8A87C / background #1A1512 / surface #221D19
```

**Ocean** (cool blue):
```
Light: primary #2563EB / background #F5F8FC / surface #FFFFFF
Dark:  primary #60A5FA / background #0C1421 / surface #151E30
```

**Forest** (green):
```
Light: primary #2E8B57 / background #F4F8F5 / surface #F9FCFA
Dark:  primary #4ADE80 / background #08140C / surface #0E1C12
```

**Plum** (violet):
```
Light: primary #7C3AED / background #F9F7FC / surface #FEFDFF
Dark:  primary #A78BFA / background #110C1F / surface #181328
```

**Slate** (neutral cool grey):
```
Light: primary #374151 / background #F6F7F8 / surface #FDFDFE
Dark:  primary #9CA3AF / background #0D0F13 / surface #16181D
```

**For a new app:** you don't need all six, but the *pattern* is worth keeping — define one canonical identity (Monochrome-equivalent) and treat every other option as a palette swap of the same eleven-token shape, never a one-off. It's what makes theming cheap later.

### 2.3 Non-negotiable: contrast is validated, not assumed

Every palette pair (`primary`↔`onPrimary`, `background`↔`onBackground`, etc.) is checked against a **minimum 3.0:1 contrast ratio** at theme-build time, and the app **asserts and fails** if any pair falls short, printing the exact ratio and a pass/fail for both the 3.0 (large text) and 4.5 (body text) WCAG thresholds. This isn't a linter you can ignore — it's load-bearing at runtime. Bring this exact discipline to a new app: pick a contrast floor, write the assertion, make a shipped build genuinely impossible if a palette regresses below it.

---

## 3. Typography

**Two typefaces, both from Google Fonts, loaded via the downloadable-fonts provider (not bundled assets):**

- **Inter** — every UI text role. Headlines, body, labels, buttons. The only face used across the entire Material-equivalent type scale.
- **IBM Plex Mono** — reserved *exclusively* for monetary figures and numeric data (transaction amounts, the Hero Panel's headline number, account balances, budget figures). Never used for prose, ever.

This split is the single most distinctive typographic decision here — worth treating as a rule, not a preference, in a new app: **if a number represents money, it's monospace; if it's a word, it's the humanist sans.** The two should never blend in the same text run.

### Type scale (size / weight / line-height / letter-spacing)

| Role | Size | Weight | Line height | Tracking |
|---|---|---|---|---|
| Display Large | 57sp | ExtraBold | 64sp | 0 |
| Display Medium | 45sp | ExtraBold | 52sp | 0 |
| Display Small | 36sp | ExtraBold | 44sp | 0 |
| Headline Large | 32sp | Bold | 40sp | 0 |
| Headline Medium | 28sp | Bold | 36sp | 0 |
| Headline Small | 24sp | Bold | 32sp | 0 |
| Title Large | 22sp | Bold | 28sp | 0 |
| Title Medium | 16sp | Medium | 24sp | 0.15sp |
| Title Small | 14sp | Medium | 20sp | 0.1sp |
| Body Large | 16sp | Regular | 24sp | 0.5sp |
| Body Medium | 14sp | Regular | 20sp | 0.25sp |
| Body Small | 12sp | Regular | 16sp | 0.4sp |
| Label Large | 14sp | Medium | 20sp | 0.1sp |
| Label Medium | 12sp | Medium | 16sp | 0.5sp |
| Label Small | 11sp | Medium | 16sp | 0.5sp |

Pattern worth noting: display/headline/title all sit at zero or near-zero letter-spacing (big type needs no help), while body and label text get *positive* tracking that increases as size decreases (small text needs the extra air to stay legible). Standard practice, correctly applied here.

---

## 4. Motion

Five named specs, not ad hoc durations scattered through the codebase:

| Name | Spec | Use |
|---|---|---|
| `micro` | 120ms, fast-out-slow-in | Small state changes — a toggle flipping, a checkbox |
| `transitionSpec` | 280ms, fast-out-slow-in | Screen-level transitions |
| `cardMove` | Spring, medium bounce, medium stiffness | A card moving between states/columns (e.g. a Kanban-style board) |
| `celebration` | Spring, low bounce, low stiffness — slower, looser | A genuine milestone moment (a debt reaching zero, a goal met) |
| `count` | 500ms, linear-out-slow-in | A number animating from one value to another (balance changes) |

**Accessibility is load-bearing here too**: every animation checks the OS-level "reduce motion" / animator-duration-scale setting before running, and skips or shortcuts if it's off. Build this check once, centrally, and have every animated component consult it — not each component reinventing its own check.

---

## 5. The Signature Pattern: The Hero Panel

This is the one component worth treating as the identity of the whole app. Structure, top to bottom:

1. **Full-bleed background in the palette's `primary` color**, extending up through the status bar (the panel owns the top of the screen, not just the content area below it).
2. **A small label row** — screen title at 70% opacity of the "on-primary" color, optional leading navigation icon.
3. **An optional pill-shaped segmented toggle** (§6) directly below the label, for switching between views of the same hero figure (e.g. "This month / Last month").
4. **The hero figure itself** — a big, composable-typed slot (not a fixed string), almost always the IBM Plex Mono numeric figure from §3, sized at Display-scale.
5. **An optional sparkline** — a smoothed cubic-bezier wave chart, drawn thin (3dp stroke, rounded caps), with a small filled-and-outlined dot marking the most recent value. Not a bar chart, not gridlines — a single continuous line, quiet and ambient rather than data-dense.
6. **Arbitrary additional content** below, still inside the same colored panel.

The whole panel is one semantically-merged accessibility node with the title as its description — screen readers get one coherent announcement, not a fragmented walk through six child elements.

**Why this is worth keeping as *the* signature pattern in a new app:** it answers "what does this app show me first" the same way every time, on every primary screen, which is exactly the kind of structural consistency that makes an app feel considered rather than assembled screen-by-screen.

---

## 6. Component Conventions

**Pill toggle (segmented control):** 24dp corner radius container, 4dp inner padding, individual pills at 20dp radius. The active pill gets a *shadow*, not just a fill — 3dp elevation tinted with the active color itself (`ambientColor`/`spotColor` both set to the accent), so it visually lifts off the track rather than just changing color. Inactive labels sit at 70–85% opacity depending on whether the toggle is on a dark or light surface.

**Bottom sheets:** 24dp top corner radius (only the top corners — it's a sheet, not a floating card), 50%-opacity black scrim, 24dp horizontal content padding, 32dp bottom padding, IME-aware (content shifts to stay visible above the keyboard), 16dp vertical spacing between child elements as the default rhythm. A dedicated "form sheet" variant adds a consistent header row — optional leading icon, title at Headline-Small, trailing close button — so every data-entry sheet in the app announces itself the same way.

**Empty states:** centered column, 32dp outer padding, then either the app's mascot character (for warmer, more prominent empty states) or a plain outlined icon at 80dp / 50% opacity (for lighter ones) — never both, never neither. 24dp gap, then body-large message text in the muted "on-surface-variant" color, then an optional primary call-to-action button. The rule worth keeping: an empty state is a moment to give direction, not just an absence — every one should offer the one next action that fills it, when there is one.

**Haptics as a semantic vocabulary:** not "trigger haptic feedback here," but named events — `selection`, `success`, `warning`, `error`, `transferMatch` — each mapped to a physical feedback type once, centrally, and called by name everywhere else. This is the same discipline as the motion specs: name the *meaning*, not the raw platform primitive, so the mapping can be tuned in one place later.

---

## 7. Portable Summary (for implementing outside Compose/Android)

If rebuilding this identity in a different stack, the load-bearing decisions to carry over, in priority order:

1. One full-bleed colored hero panel per primary screen, with a big monospace number as its centerpiece.
2. Two-typeface split: humanist sans for words, monospace for numbers that represent money — enforced as a rule, not a suggestion.
3. Semantic color (income/transfer/warning/danger) kept structurally separate from brand/identity color, so theming never accidentally changes what "danger" looks like.
4. A contrast-ratio assertion that can fail a build — pick the floor, write the check, make it real.
5. Named motion and haptic vocabularies (`celebration`, `transferMatch`, etc.) rather than raw durations and feedback types scattered inline.
6. Empty states that always offer the next action, not just an illustration.
