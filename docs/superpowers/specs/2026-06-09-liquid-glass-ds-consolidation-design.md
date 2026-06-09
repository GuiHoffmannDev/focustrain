# Liquid Glass DS Consolidation — Design

**Date:** 2026-06-09
**Branch context:** `feat/cities-sqlite-clean-home`
**Status:** Approved design, pending spec review

## Summary

The app already adopts iOS 26 Liquid Glass broadly: 27 files call the
`ftGlass*` View helpers or `.glassEffect` directly, and every component the
original plan listed as "to migrate" is already on glass. This work is therefore
**a refactor/consolidation, not a redesign**. We formalize a small, opinionated
`FTGlass` design-system layer (Approach C — hybrid), route existing call sites
onto it without visual change, finish the few surfaces still on ad-hoc materials,
codify state/tint rules, and add `GlassEffectContainer` grouping where sibling
glass currently stacks blurs.

Deployment target is iOS 26.5, so all Liquid Glass APIs are available
unconditionally (no availability fallbacks needed).

## Goals

1. **Formalize the DS API** — collapse loose helpers into a named, composable set.
2. **Finish the edges** — migrate remaining ad-hoc `.ultraThinMaterial` / opacity
   fills onto the glass layer.
3. **Consistency pass** — one definition of idle/selected/disabled, shapes, and
   tint-as-accent rules, applied at the API level.
4. **Accessibility / contrast** — preserve labels and `.disabled`, gate
   `.interactive()` to tappable controls, verify contrast over map/gradient.

## Non-Goals

- No visual redesign. Every major screen is **feel-only** (see Locked Screens).
- No new features, no layout/spacing/composition changes on locked screens.
- No unrelated refactoring outside the glass surface.

## Hard Constraint — Locked Screens (feel-only)

These screens must look identical before/after. Allowed changes are limited to
swapping an ad-hoc material for `FTGlassSurface` and wrapping sibling glass in a
container. Any visible delta means revert that change.

- Live session — `SessionView`
- All Onboarding screens (Welcome, BrandReveal, MapPreview, QuietCarriage, Ready, …)
- `ArrivalView` and `SessionPauseMenu`
- BoardingPass flow (`BoardingPassView`) and `SeatPickerView`

Each locked screen gets a before/after Simulator screenshot in verification.

Surfaces that MAY receive consistency adjustments (not locked): Home bottom
stack, `DurationPickerView`, History/Trends/Settings filters, `CityPickerView`,
`SoundOverlay`.

## Approach C — Hybrid (chosen)

Considered three approaches:

- **A. Modifier-first** — keep `ftGlass*` extensions, add tokens only. Lowest
  churn, but leaves duplicated press/haptic logic in `CTAButton` &
  `SheetActionCard`.
- **B. Component-first** — full wrapper components per the original plan. Cleanest
  call sites, largest refactor, highest risk of visual drift on locked screens.
- **C. Hybrid (chosen)** — one primitive as source of truth, one `ButtonStyle`
  for the press/haptic pattern, thin semantic components composing those. Kills
  the real duplication while keeping all existing call sites compiling, so locked
  screens don't move.

## API Surface

New file: `Core/DesignSystem/Components/FTGlass.swift`. One call to
`.glassEffect(...)` exists in the codebase after this work — inside
`FTGlassSurface`.

### 1. `FTGlassSurface` — the single primitive

```swift
enum FTGlassShape { case capsule, circle, rounded(CGFloat) }

struct FTGlassSurface: ViewModifier {
    var shape: FTGlassShape
    var interactive: Bool = false
    var tint: Color? = nil
    var selected: Bool = false   // drives the standard selected stroke + lift
}

extension View {
    func ftGlass(_ shape: FTGlassShape,
                 interactive: Bool = false,
                 tint: Color? = nil,
                 selected: Bool = false) -> some View
}
```

The existing `ftGlassCapsule` / `ftGlassCircle` / `ftGlassRounded` extensions are
**reimplemented as thin wrappers over `FTGlassSurface`** — all 27 current call
sites keep compiling unchanged with zero visual delta. New code uses `.ftGlass`.

### 2. `FTGlassButtonStyle` — a real `ButtonStyle`

Captures the press-scale + haptic pattern currently hand-rolled (DragGesture +
`@State pressed` + `UIImpactFeedbackGenerator`) in `CTAButton` and
`SheetActionCard`.

```swift
struct FTGlassButtonStyle: ButtonStyle {
    var shape: FTGlassShape
    var tint: Color? = nil
    var haptic: UIImpactFeedbackGenerator.FeedbackStyle? = .medium
    var pressedScale: CGFloat = 0.97
}
```

### 3. `FTGlassChip`

Thin composition of `FTGlassButtonStyle` + the selected rules, extracted from the
current `ScenarioChips` implementation. Callers: `ScenarioChips`,
`FocusModeChips`, `FilterChip`.

### 4. `FTGlassCardButton`

The `SheetActionCard` shape generalized: leading icon badge, title/caption,
trailing chevron. `SheetActionCard` becomes a thin caller.

### 5. `FTGlassIconButton` (keep)

Already correct. Re-pointed at `FTGlassSurface` internally; public API unchanged.

### 6. `FTGlassContainer`

Thin wrapper over Apple's `GlassEffectContainer` so grouping reads consistently
and is the single place container tuning lives.

## State & Tint Rules (codified in FTGlassSurface / FTGlassChip)

| State | Surface | Stroke | Lift | Foreground |
|---|---|---|---|---|
| idle | `.regular` (`.interactive()` if tappable) | white 0.08, 1pt | — | textPrimary / white |
| selected | `.regular.tint(tint)` | brandRail 0.85, 2pt | scale 1.03 | ink (white when tint dark) |
| disabled | idle surface | idle | — | 0.4 opacity, hit-testing off |

Invariants:

- `.interactive()` is applied **only** when the surface backs a tappable control.
- **Tint is an accent, never a flat fill** — selected state keeps glass
  translucency via `.tint`, not an opaque `.fill`.
- Coloured controls (e.g. ambient sound) soften tint to `tint.opacity(0.45)`,
  matching today's `SessionControlButton`.
- `brandRail` resolves to white (per the brand-accent decision), so the selected
  stroke reads as a bright rim, not red.

## GlassEffectContainer Grouping

Add `FTGlassContainer { }` where sibling glass elements currently stack blurs:

- `SessionControlPill` — wraps the pill background + its `SessionControlButton`
  children. Fixes confirmed double-glass (pill paints a glass capsule while each
  child paints its own glass circle). **Feel-only**: composition identical, blur
  stops doubling.
- Home bottom stack (the three `SheetActionCard`s).
- Onboarding top bar.
- Chip grids (`ScenarioChips`, `FocusModeChips`).
- History filter bar.
- Trends segmented picker.
- `SoundOverlay` controls.

The pill's own background stays; the container only lets children morph rather
than layer.

## Migration Map (3 commits)

**Commit 1 — DS layer.** Add `FTGlass.swift` (`FTGlassSurface`,
`FTGlassButtonStyle`, `FTGlassChip`, `FTGlassCardButton`, `FTGlassContainer`).
Reimplement `ftGlass*` extensions, `FTGlassIconButton`, `CTAButton`, and
`SheetActionCard` on top. No call-site changes elsewhere.

**Commit 2 — chips/selectors.** Route `ScenarioChips`, `FocusModeChips`,
`FilterChip`, `RangePicker`, `PickerCard`, `MapStyleSelector`, and symbol/colour
cells through `FTGlassChip` / `FTGlassSurface`; add containers to the grids.

**Commit 3 — edges & sheets.** Migrate remaining ad-hoc
`.ultraThinMaterial` / opacity fills (onboarding screens, `SessionPauseMenu`,
`ArrivalView`, `SoundOverlay`, Settings/Trends close/back buttons →
`FTGlassIconButton`); add remaining containers.

## Accessibility & Contrast

- Preserve all existing `accessibilityLabel` / `accessibilityValue` and
  `.disabled`.
- Audit `.interactive()` — tappable controls only.
- `CTAButton` loading state + haptics unchanged.
- Contrast check for glass over map/gradient backgrounds (primary readability
  risk).

## Verification

- `swift test` (Tests/CitiesHarness) green.
- Simulator build with `CODE_SIGNING_ALLOWED=NO`.
- Manual screenshot pass: Onboarding, Home, DurationPicker, SeatPicker,
  BoardingPass, Session, SoundOverlay, PauseMenu, Arrival, History, Trends,
  Settings, CityPicker — checking contrast, consistent shapes, and **no
  double-glass**.
- Locked screens: before/after screenshot diff; any visible delta = revert.

## Risks

- **Visual drift on locked screens** — mitigated by feel-only constraint +
  before/after screenshots.
- **Container morphing changing perceived layout** — verify each container site
  individually; pill is the highest-risk site.
- **Tint-as-fill regressions** — the selected-state rule must stay translucent;
  watch colour cells and ambient-sound controls.
