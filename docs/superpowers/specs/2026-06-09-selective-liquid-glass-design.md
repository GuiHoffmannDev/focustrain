# Selective Liquid Glass — Design

**Date:** 2026-06-09
**Branch context:** `feat/cities-sqlite-clean-home`
**Status:** Approved by user

## Context

Earlier today Liquid Glass was reverted app-wide: `FTGlassSurface` now renders a
solid tint or `.ultraThinMaterial` and never calls `.glassEffect` (backup stash:
`backup-wip-pre-glass-revert-20260609-125744`). The user reported three issues:

1. Session-view controls (pause/play, music, camera pill, map, tunnel) read as
   flat gray frosted material instead of translucent Liquid Glass.
2. Close/back buttons placed inside `.toolbar` show **double chrome**: iOS 26
   wraps toolbar items in native Liquid Glass, and `FTGlassIconButton` paints its
   own frosted circle inside it.
3. In the sound overlay, the selected `AmbientSoundCard` leaks its colour as a
   square: the `LinearGradient` overlay is not clipped to the rounded card shape
   (visible in reference screenshot IMG_3807).

## Decision (user-approved scope)

Liquid Glass returns **only** on:

- Session-view circular controls: pause/play, music, the camera `SessionControlPill`
  (fit-route / center-train), map style, tunnel toggle — each standalone button
  stays an independent glass circle (no extra merging containers).
- Close/back icon buttons across the app (`FTGlassIconButton`).

Everything else (CTAs, chips, cards, panels, sheets) keeps today's post-revert
rendering. This is a surgical opt-in, **not** a revert of the revert.

## Design

### 1. `FTGlassSurface` gains an opt-in `liquid` mode

`FTGlass.swift` stays the only `.glassEffect` call site. `.ftGlass(...)` gains
`liquid: Bool = false`. When `true`, render the original glass matrix
(`.regular` / `.tint(t)` / `.interactive()` per flags) inside the existing shape;
when `false`, behaviour is unchanged. `FTGlassContainer` becomes a real
`GlassEffectContainer` again — needed so the pill capsule and its child circles
merge instead of stacking blur; it is a visual no-op for non-glass children.

### 2. Opt-in call sites

- `SessionControlButton`: idle → interactive glass circle; active → glass with
  white 0.75 tint.
- `SessionControlPill`: capsule background → glass (non-interactive).

**Amendment (post-device check):** buttons *inside* the pill must not paint
their own glass — nested `glassEffect` shapes merge inside the container and
smear the glyphs (metaball artifact, IMG_3814). The pill sets a
`sessionControlGrouped` environment flag; grouped buttons render no idle chrome
(the capsule provides the glass) and a plain `white.opacity(0.75)` circle when
active. The pill no longer wraps content in `FTGlassContainer` since the capsule
is its only glass surface.
- `FTGlassIconButton`: glass circle (covers History, Onboarding, BoardingPass,
  Trends, SoundOverlay close/back buttons).
- Legacy `ftGlassCapsule/Circle/Rounded` helpers gain a `liquid` pass-through.

### 3. Toolbar close/back buttons drop the custom background

Four sites render `FTGlassIconButton` inside `ToolbarItem`: SessionView map-style
sheet (xmark), SettingsSheet (xmark), DurationPickerView (chevron.left),
SeatPickerView (chevron.left). Replace with a plain `Button` + `Image` label so
the system toolbar Liquid Glass is the only chrome. Keep existing accessibility
labels and white foreground.

### 4. `AmbientSoundCard` gradient clip

Clip the selected-state `LinearGradient` overlay to
`RoundedRectangle(cornerRadius: 20, style: .continuous)` (the glyph overlay
already clips itself).

## Verification

- Simulator build with `CODE_SIGNING_ALLOWED=NO` succeeds.
- `.glassEffect` appears only in `FTGlass.swift`.
- Visual: session controls translucent over the map; toolbar X/back buttons show
  a single glass circle; selected sound card colour stays inside the rounded
  shape.

## Out of scope

- No changes to CTAButton, chips, Home cards, panels, or sheet backgrounds.
- The backup stash is left untouched.
