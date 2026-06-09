# Active Session Redesign — Phase 2 Implementation Plan

> Successor to `docs/superpowers/plans/2026-06-02-active-session-redesign-phase1-visual.md` (Phase 1 complete at commit `545ea1f`).

## Context

After running Phase 1 in the simulator, the user reviewed the live SessionView and asked for behavior + design changes:

1. **End (X) button** should be hidden during the active ride — only appears when the session is paused (signaling "you've stopped, do you want to end?")
2. **Pause must actually work** — real timer freeze/resume, not just visual state. State must persist across backgrounding (Ticket is JSON in UserDefaults).
3. **Chrome buttons should use iOS 26 liquid glass** (`.glassEffect()`). Deployment target is already iOS 26.5; codebase currently uses legacy `.ultraThinMaterial` in 19 places but no `glassEffect` yet.
4. **Right-side layout** changes: 1 vertical pill with 2 route-control buttons (fit-to-route + center-on-train, today fused into a single `follow` toggle) PLUS 2 standalone buttons (map style + rail mode).
5. **Map style button** opens the existing `MapStyleSelector` as a sheet modal (the "Choose Map Style" 2×2 grid + Labels toggle the user showed in reference Image 2) instead of the current inline `Menu` dropdown.
6. **Tunnel → Rail mode** — the moon/moon.zzz.fill button is renamed Rail (icon + a11y), behavior unchanged.
7. **Monochrome map fix** — `MapStyle.monochrome` currently uses `MKStandardMapConfiguration(emphasisStyle: .muted)` which only desaturates colors slightly. User wants real preto/cinza. ([MapStyle+MapKit.swift:9](FocusTrain/Core/Map/MapStyle+MapKit.swift#L9))
8. **Sound modal** — replace music Menu with a redesigned Sound sheet (reference Image 3) showing categorized cards (White Noise / Focus Sound), new ambient scenarios (airplane, raindrop, ocean waves), header ON toggle, AirPlay output picker, "Coming Soon" Focus Sound card.

**Scope split.** Items 1–7 are incremental edits to existing files and reusing existing components. Item 8 is substantial: new data model (`FocusScenario` currently has 5 generic cases; new design requires airplane/raindrop/ocean-waves which don't exist), new view + cards, audio engine work to actually play the new sounds, AirPlay integration. **This plan covers items 1–7. Item 8 goes to a separate Phase 3 brainstorm + plan session.**

## Architecture

### Pause data model

`Ticket` (Codable JSON in UserDefaults via `SessionStore`) gains:

```swift
var pausedAt: Date?            // wall-clock instant the current pause started
var pausedAccumulated: TimeInterval = 0   // total paused time across the journey
```

`SessionStore` gains symmetric `pause()` / `resume()` methods that mutate the active ticket (the `didSet` persists). Pausing the same already-paused ticket is a no-op (idempotent, like `updateScenario`).

`SessionViewModel.elapsed` becomes:

```swift
var elapsed: TimeInterval {
    let raw = max(0, now.timeIntervalSince(ticket.departDate))
    let currentlyPaused = ticket.pausedAt.map { max(0, now.timeIntervalSince($0)) } ?? 0
    return max(0, raw - ticket.pausedAccumulated - currentlyPaused)
}
```

This anchors against the wall-clock and survives background/force-quit cleanly. `isPaused: Bool` is `ticket.pausedAt != nil`. `pause()` stores `Date.now` on `pausedAt`; `resume()` adds `now - pausedAt` to `pausedAccumulated` then clears `pausedAt`.

### Right-side layout

Inside the root `ZStack`, the chrome `HStack` shifts to:

```
LEFT pill (unchanged: pause + music)
        Spacer
                 VStack(spacing 12):
                     SessionControlPill {
                         fit-route button
                         center-train button
                     }
                     standalone map-style button
                     standalone rail-mode button
```

Standalone buttons reuse `SessionControlButton`'s visual styling (40pt capsule, glass background) but without the `SessionControlPill` wrapper — they float as individual capsules with the same liquid-glass surface.

**Camera modes.** Today `followTrain: Bool` drives a single toggle inside `RouteMapView`. The split into two buttons makes them mutually-exclusive radio-style: an enum `CameraMode { case fitRoute, centerTrain }` replaces `followTrain`. The fit button is `.active` when `cameraMode == .fitRoute`; the center button is `.active` when `cameraMode == .centerTrain`. `RouteMapView`'s `follow: Bool` param maps to `cameraMode == .centerTrain`.

### Liquid glass

Replace `SessionControlPill` background:

```swift
// before
.background(Capsule().fill(FT.Palette.bgElevated.opacity(0.5)))
.overlay(Capsule().stroke(FT.Palette.textMuted.opacity(0.25), lineWidth: 1))

// after
.glassEffect(.regular, in: Capsule())
```

Same treatment for the standalone-button wrapper. iOS 26 `.glassEffect(_:in:)` provides native chromatic adaptation (auto-light on bright map regions, auto-dark on tunnels/satellite). Drop the manual stroke — the glass surface includes its own subtle border.

`SessionEndButton` and `SessionMusicMenu` already mirror `SessionControlButton.idle` styling — they pick up the same glass treatment via the shared helper.

### Map style sheet

Convert `mapStyleMenu` inline `Menu` into a button that toggles `@State private var showMapStyleSheet = false`. The sheet wraps `MapStyleSelector`:

```swift
.sheet(isPresented: $showMapStyleSheet) {
    NavigationStack {
        MapStyleSelector(selection: $mapStyle, showLabels: $showLabels)
            .padding()
            .navigationTitle("session.mapstyle.title")
            .toolbar { ToolbarItem(.topBarTrailing) { closeXButton } }
    }
    .presentationDetents([.fraction(0.55)])
    .presentationBackground(.ultraThinMaterial)
    .presentationDragIndicator(.visible)
}
```

`showLabels` is currently read once at SessionView construction from `UserDefaults`. To make the labels toggle reactive in the modal, promote it to `@AppStorage("mapShowLabels")` in SessionView. `MapStyleSelector` already accepts `@Binding var showLabels` — clean fit.

The close X button follows the `SettingsSheet` pattern ([SettingsSheet.swift:25–36](FocusTrain/Features/Settings/Views/SettingsSheet.swift#L25-L36)) — 30pt circle with `xmark` glyph and `bgElevated.opacity(0.6)` background.

### Rail rename

- SF Symbol mapping: idle `tram.tunnel.fill` (or `train.side.front.car`); active `tram.tunnel.fill` with white tint (handled by `SessionControlButton.active` state).
- Add localization keys: `session.rail.on` / `session.rail.off` ("Rail mode on" / "Rail mode off"; pt-BR "Modo trilho ligado" / "Modo trilho desligado"). Keep `session.tunnel.on/off` as deprecated for now — strip in Phase 3 cleanup.
- The underlying `InAppTunnelController` stays named as-is — it's internal plumbing. Rail is a UI rename.

### Monochrome fix

Approach: when `mapStyle == .monochrome`, apply `.saturation(0)` to `RouteMapView` in SessionView. This is a SwiftUI-level visual filter; no MKMapView delegate changes needed. The existing `MKStandardMapConfiguration(emphasisStyle: .muted)` base provides the correct geometry/labels; saturation collapses the residual color to true grayscale.

Alternative considered: `MKHybridMapConfiguration` (satellite + roads) gives a gray-toned aerial view but changes the visual identity too much — user's reference suggests true monochrome of the road map, not satellite.

Edge: `.saturation(0)` also affects the TunnelHero glow that floats on top. To preserve TunnelHero colors, apply the modifier on `RouteMapView` only, not on the parent `ZStack`. The hero is a sibling, not a child.

### End button visibility

`SessionEndButton` already owns its dialog state. Wrap its emission in SessionView with `if model.isPaused`. No other changes to SessionEndButton itself.

## Files

**Modify:**

- `FocusTrain/Core/Persistence/Ticket.swift` — add `pausedAt: Date?` + `pausedAccumulated: TimeInterval` to the Codable struct
- `FocusTrain/Core/Persistence/SessionStore.swift` — add `pause()` / `resume()` (mirror `updateScenario`)
- `FocusTrain/Features/FocusSession/ViewModels/SessionViewModel.swift` — update `elapsed`, add `isPaused`, add `pause()` / `resume()` proxy methods
- `FocusTrain/Core/Map/MapStyle+MapKit.swift` — no change here (saturation applied at SwiftUI layer instead)
- `FocusTrain/Core/DesignSystem/Components/SessionControlPill.swift` — swap background to `glassEffect`
- `FocusTrain/Core/DesignSystem/Components/SessionControlButton.swift` — adopt `glassEffect` per state
- `FocusTrain/Features/FocusSession/Views/Components/SessionEndButton.swift` — `glassEffect` surface
- `FocusTrain/Features/FocusSession/Views/Components/SessionMusicMenu.swift` — `glassEffect` surface
- `FocusTrain/Features/FocusSession/Views/SessionView.swift` — biggest delta: new `cameraMode` enum, new pause wiring, conditional end button, right-side restructure (1 pill + 2 standalone), map style sheet, rail rename, monochrome saturation
- `FocusTrain/Resources/Localizable.xcstrings` — add `session.rail.on`, `session.rail.off`, `session.mapstyle.title`, `session.fit.route`, `session.center.train`, `session.pause.a11y`, `session.resume.a11y`

**Reused (no changes needed):**

- `MapStyleSelector` (`Core/DesignSystem/Components/MapStyleSelector.swift`) — used inside the new sheet
- All Phase 1 components (`SessionTitleLabel`, `SessionMetricTile`, etc.) — unchanged

**Not created.** Phase 2 stays inside the existing file set; the only "new" code is one enum (`CameraMode`) declared inside SessionView.swift.

## Tasks (suggested split, 8 tasks)

Each task ends with `xcodebuild build` green + own commit. Same subagent-driven-development workflow as Phase 1.

1. **Add pause fields to `Ticket`** + JSON migration safety (Codable default values).
2. **Add `pause()` / `resume()` to `SessionStore`** + update `SessionViewModel.elapsed` for paused-aware accounting + `isPaused` derived.
3. **Adopt `.glassEffect()` in `SessionControlPill`, `SessionControlButton`, `SessionEndButton`, `SessionMusicMenu`.** Visual-only change; no API surface change.
4. **Right-side restructure in SessionView**: introduce `CameraMode` enum, split follow toggle into fit-route + center-train buttons inside a 2-button pill, lift map + rail out as standalone capsules.
5. **Conditional end-button visibility**: wrap `SessionEndButton` in `if model.isPaused`. Wire the left pill's pause button to `state: model.isPaused ? .active : .idle` and connect tap to `model.pause()` / `model.resume()`.
6. **Map style sheet modal**: replace inline `mapStyleMenu` with a sheet that wraps `MapStyleSelector`; promote `mapShowLabels` to `@AppStorage` for reactive labels toggle.
7. **Rail rename**: SF Symbol + a11y keys + add `session.rail.on/off` localization keys.
8. **Monochrome fix**: apply `.saturation(0)` conditionally on `RouteMapView` when `mapStyle == .monochrome`.

Plus a final localization-keys task (similar to Phase 1 Task 9) adding the new strings via Xcode's String Catalog editor — the user prefers to do this manually.

## Verification

Manual smoke test in iPhone 17 Pro simulator. Cannot be automated (no XCTest target). After each task ends with `xcodebuild build` green; final verification:

- [ ] Start a 1-minute session. X button is **not visible**; pause is `.idle`.
- [ ] Tap pause. Pause turns `.active` (solid white). X appears top-right. Train stops moving on map. Timer freezes.
- [ ] Wait 5s. Tap pause again. Train resumes from frozen position. X hides. Time-remaining tile reflects the lost 5s (i.e., total ride time effectively extended).
- [ ] Background the app for 10s while paused; return. State is preserved (still paused, X still showing).
- [ ] Tap the standalone **map** button → sheet slides up with `MapStyleSelector` 2×2 grid + Labels toggle. Tap a different style; sheet closes; map re-renders with new style.
- [ ] Switch to Monochrome; map renders as black/gray with no color tones.
- [ ] Tap **rail** (was tunnel). Rail glyph turns white; TunnelHero scrim activates. Tap again to deactivate.
- [ ] Tap **fit-route** button in the route pill. Camera zooms out to show full A→B route. Center-train button becomes idle.
- [ ] Tap **center-train**. Camera follows train. Fit-route becomes idle.
- [ ] All button surfaces have the iOS 26 glass look (subtle blur + chromatic shift over bright map regions).
- [ ] VoiceOver labels read correctly for all renamed/added controls.

## Out of scope (Phase 3, separate plan)

- Sound modal redesign with new ambient scenarios (airplane, raindrop, ocean waves)
- Audio engine refactor for white-noise vs focus-sound categories
- AirPlay output picker integration
- "Coming Soon" placeholder cards in the modal
- Cleanup of deprecated `session.tunnel.on/off` keys (kept in Phase 2 to avoid stale-key warnings during the rename)

These need their own brainstorm + plan session because they involve new data architecture (FocusScenario expansion) and audio system work.
