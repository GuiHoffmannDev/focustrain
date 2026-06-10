# Light Mode — Design

**Date:** 2026-06-09
**Branch context:** `feat/light-mode` (from `feat/cities-sqlite-clean-home` @ `a055e90`)
**Status:** Implemented
**Plan:** [`../plans/2026-06-09-light-mode.md`](../plans/2026-06-09-light-mode.md)

## Context

The app was 100% dark-mode-only: dark was forced at 5 points
(`.preferredColorScheme(.dark)` ×3 + `overrideUserInterfaceStyle = .dark` on the
two MapKit views) and `FT.Palette` (Colors.swift) held fixed hex values. The goal
was to follow the **device appearance** (no in-app toggle) while keeping **Dark
pixel-for-pixel identical** to before.

## Decisions (user-approved)

1. **Tokens in code, not asset catalog.** `FT.Palette` stays the single source;
   each adaptive token becomes a light/dark pair via a `UIColor` dynamic provider
   (`Color(light:dark:)`).
2. **Stars disappear in light.** `StarsBackground` only renders in dark (gated at
   the HomeView call site). WelcomeScreen's white star Canvas vanishes naturally
   over the light backdrop.
3. **Accent in light.** `brandRail` / `railLine` resolve to charcoal `#333333`.
4. **Light surfaces.** `bgPrimary` → off-white `#F5F5F7`; `bgElevated` → `#FFFFFF`.

## The token model

`Color(light:dark:)` builds a `UIColor { trait in … }` dynamic provider. The
**dark branch reproduces the previous static hex byte-for-byte** — dark is the
locked baseline, so any dark delta is a bug. Adaptive tokens:

| Token | Dark (locked) | Light |
|---|---|---|
| `bgPrimary` | `#000000` | `#F5F5F7` |
| `bgElevated` | `#0F1729` | `#FFFFFF` |
| `brandRail`/`railLine` | `#FFFFFF` | `#333333` |
| `textPrimary` | `#FFFFFF` | `#1A1A1A` |
| `textSecondary` | `#9CA3AF` | `#5B616B` |
| `textMuted` | `#6B7280` | `#8E939B` |
| `gray800` | `#1E1E1E` | `#E5E6E8` |

New semantic tokens (dark value = prior literal): `strokeHairline`, `strokeCard`,
`scrim` (= `bgPrimary`), `shadowSoft`, `controlActiveTint`, `controlActiveGlyph`,
`chipSelectedTint`, `chipSelectedFg`.

`black`/`white` stay absolute primitives; `brandBrass`, `ink`, `surfaceLight`,
`success`, the `Scenario.*` pastels stay static (they read in both schemes).

### Gotchas (documented in Colors.swift)

- `.opacity()` over a dynamic token re-resolves live — use it when the alpha is
  equal in both schemes; bake the alpha into the provider when it differs.
- Never extract `cgColor` / `UIColor(Color)` from a dynamic token — it freezes one
  scheme.
- `MKOverlayRenderer` / `CALayer` / `UIImage` don't follow a dynamic provider
  reliably → resolve static colors by flag and re-apply on the scheme flip.

## Map chrome (`Core/Map/MapChrome.swift`)

terra and satellite carry **dark imagery in both schemes**, so chrome drawn over
them must stay light there:

```
MapStyle.usesDarkChrome(for: scheme) = scheme == .dark || self == .terra || .satellite
```

`MapChromeColors.dark` = exact current values (route line white, ring white-0.5,
pin borders white…); `.light` = charcoal (`#333`/`#1A1A1A`), ghost `#333`-0.4,
train glow black-0.25. Pin/train **bodies stay dark** (physical markers) and their
**glyphs stay white**; only rims, glow, lines and dots move to charcoal.

- **UIKit side** (`RouteMapView`, `JourneyMapView`, `DestinationMapView`): the
  representable gains `@Environment(\.colorScheme)` (so `updateUIView` fires on the
  flip), the coordinator stores `appliedDarkChrome`, and on flip re-adds the active
  overlay (new renderer), re-rasterises endpoint/origin dot images, and re-styles
  the train / pins (CGColor isn't dynamic). MapKit tiles re-render themselves via
  the trait once the forced override is gone.
- **SwiftUI side** (chrome over the map): `style.usesDarkChrome(for:)` decides
  scrim (`black` vs `scrim`) and text (`white` vs `textPrimary`) in SessionView,
  SessionMetricTile (`onDarkBackdrop`), DurationPickerView, HomeView vignettes,
  TimeRulerView (`rulerInk`). JourneyMapScreen is always monochrome → plain scheme
  tokens. The monochrome desaturation (saturation blends) is **untouched** —
  desaturating light tiles already yields the white-with-greys look.

## "Paper / physical object" rule

Surfaces that must look **identical in both schemes** pin to absolutes:
`TrainTicketCard`, `TicketBodyView`, `TicketStubView` swap `brandRail` → absolute
`white`; `TunnelHero` keeps its dark vignette and pins `brandRail` → `white`;
`TearableTicketView`/`PrinterSlotView`/`DotMatrixMapView`, the brass SubscribeBanner,
and `GiveUpHoldRow`'s `.difference` hold-pill stay absolute.

## Verification

- Build per phase (`xcodebuild … -destination 'iPhone 17 Pro' CODE_SIGNING_ALLOWED=NO`)
  + `swift test` (Tests/CitiesHarness) green.
- Dark guaranteed by the byte-for-byte invariant (dark token = prior literal).
- Light-mode previews on FTGlass, SessionControlButton, TrainTicketCard.
- Live scheme switch (`xcrun simctl ui booted appearance light|dark`): tokens
  re-resolve, MapKit tiles re-render via trait, custom chrome re-applies via the
  `appliedDarkChrome` path.

## Outstanding (polish)

- `SessionTitleLabel` has no app call sites (previews only) — left dark, TODO.
- PulsingPin / ConfettiCanvas white over a light satellite backdrop: judge by eye.
- Scenario pastels as foregrounds over light glass: darken only the fgs if they
  wash out.
