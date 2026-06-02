# Active Session Redesign

**Date:** 2026-06-02
**Scope:** `SessionView` (live ride). Two phases — visual overhaul, then real Pause.

## Goal

Bring `SessionView` to a flight-tracker-inspired layout: the map and the train become the heroes, chrome retreats to the corners and edges as floating control pills and small metric tiles. Add a real Pause capability that freezes time and survives backgrounding.

Reference: a flight tracking UI with a vertical route line, the vehicle centered on the line, two vertical control pills hugging the screen sides, the destination name floating above as a large outlined label, and the time/distance metrics tucked into the bottom corners.

We keep our curved geodesic map — not a vertical line — but adopt the rest of the reference's structure.

## Non-goals

- No change to the duration picker or the boarding pass flow.
- No new map provider; `RouteMapView` stays.
- No persistence of map style per-ticket beyond what exists today.
- No telemetry or analytics work.

## Phase 1 — Visual redesign

### Layout

```text
┌─────────────────────────────────────────┐
│  ╭─Ricardo Flores Magón─╮       ⓧ End  │
│                                          │
│  ⏸                              ◐ Tunnel│
│  ♪                              ⊕ Follow│
│                                 ▦ Map  │
│                                          │
│        (real geodesic map,               │
│         train follows curved route)      │
│                                          │
│                                          │
│  TIME REMAINING        DISTANCE REMAINING│
│  259 min               3.268 km          │
└─────────────────────────────────────────┘
```

- `RouteMapView` keeps `.ignoresSafeArea()` underneath.
- Top + bottom scrim gradients preserved (legibility).
- `TunnelHero` overlay preserved (full-screen vignette when Tunnel active).
- Title and metrics positioned via `ZStack` with safe-area-respecting padding.
- Control pills hug the horizontal safe-area edges with `FT.Layout.sideMargin` inset.

### Components (new + extracted)

| Component | Location | Responsibility |
|---|---|---|
| `SessionTitleLabel` | `Core/DesignSystem/Components/` | Large white bold text with thick dark outline (stroke + drop shadow) — readable over any map area. Reusable on any "label-on-map" screen. |
| `SessionControlPill` | `Core/DesignSystem/Components/` | Vertical container with capsule background (`bgElevated.opacity(0.5)` + thin stroke). Takes child buttons via `@ViewBuilder content: () -> Content`. |
| `SessionControlButton` | `Core/DesignSystem/Components/` | 40pt circular button. States: `idle`, `active` (solid white fill, ink-colored icon), `disabled` (0.4 opacity, no tap). Accepts SF Symbol name + action + `isActive: Bool`. |
| `SessionMetricTile` | `Core/DesignSystem/Components/` | Uppercase muted label + large white value. Horizontal alignment parameter (`.leading` or `.trailing`). |
| `SessionEndButton` | `Features/FocusSession/Views/Components/` | Top-right X. Encapsulates the `showEndConfirm` state + `confirmationDialog` that today leaks into the parent view. |
| `SessionMusicMenu` | `Features/FocusSession/Views/Components/` | Extracts the inline `Menu` of `FocusScenario` from today's `musicButton`. |
| `SessionView` | (existing) | Slimmer container: `RouteMapView`, scrim, `TunnelHero`, title + end button (top), two control pills (sides), two metric tiles (bottom). |

All new files live in Xcode synced groups — they enter the target automatically.

### Top region

- **`SessionTitleLabel`** centered horizontally at top, shows the destination's full city name via `StationPool.station(forCode: ticket.toCode)?.city`. White bold, thick dark outline (≈3pt stroke approximated by 8-direction shadowed Text or single Text + `.shadow` × N). Falls back to `ticket.toCode` if the city lookup misses.
- **`SessionEndButton`** isolated top-right. Visually identical to today's X (40pt black-circle, muted stroke, white glyph).
- Today's `routeRow` (FROM→TO badges) and `ticket.code` row are removed.

### Left control pill (top → bottom)

1. **Pause button** — `SessionControlButton` with icon `pause.fill`. In Phase 1, this button is rendered in `disabled` state (opacity 0.4, inert). No tap feedback, no tooltip. The pill remains symmetrical with the right side; the button signals "coming".
2. **Music button** — `SessionControlButton` icon `music.note`. Tap presents `SessionMusicMenu`. Behavior identical to today (scenario list with checkmark on current, `session.updateScenario` side-effect).

### Right control pill (top → bottom)

1. **Tunnel button** — `SessionControlButton`. Inactive: icon `moon`, white glyph on dark capsule. Active: solid white fill, `moon.zzz.fill` glyph in `FT.Palette.ink`. Tap calls `tunnel.toggle()` inside `withAnimation(.spring(response: 0.4, dampingFraction: 0.82))` — same curve as today. No label.
2. **Follow button** — `SessionControlButton`. Default-on. Active (following train): icon `scope`, button styled like active toggle. Inactive (fit route): icon `tram.fill`. Tap toggles `followTrain` + `.light` haptic, same animation.
3. **Map style button** — `SessionControlButton` icon `map`. Tap presents a `Menu` with `MapStyle.monochrome` / `.standard` / `.hybrid`. Selected option carries `checkmark`. Updates via a new `session.updateMapStyle(...)` method (added in `SessionStore`, mirrors the existing `updateScenario`).

### Bottom region

- **`SessionMetricTile`** (leading) — label `session.time.remaining` ("Time Remaining" / "Tempo Restante"), value `model.remainingMinutesText` formatted "{N} min" for ≥60s, "<1 min" for under a minute.
- **`SessionMetricTile`** (trailing) — label `session.distance.remaining` (existing key), value `model.remainingDistanceText` (existing, "3.268 km" style).

Tiles sit at the bottom safe-area edge with `FT.Layout.sideMargin` horizontal inset. Each is a `VStack` (label small uppercase muted, value large white bold).

### SessionViewModel additions (Phase 1)

- `remainingMinutesText: String` — new derived property. Returns "N min" rounded from `remaining / 60`, or "<1 min" when `remaining < 60`.

No other VM changes in Phase 1.

### Animations

Preserve `appeared` flag with `.spring(response: 0.5, dampingFraction: 0.85)`. Per-region entrance:

- **Title** — `.offset(y: -16)` → 0, opacity 0 → 1.
- **End button** — opacity 0 → 1, no offset.
- **Left pill** — `.offset(x: -30)` → 0, opacity 0 → 1.
- **Right pill** — `.offset(x: 30)` → 0, opacity 0 → 1.
- **Metric tiles** — `.offset(y: 24)` → 0, opacity 0 → 1.

All in parallel under the same spring.

### Localization (new keys)

Add to `Localizable.xcstrings`:

- `session.time.remaining` — "Time Remaining" / "Tempo Restante"
- `session.distance.remaining` — verify existing; if absent, "Distance Remaining" / "Distância Restante"
- `session.minutes.unit` — "min" / "min"
- `session.minutes.lt1` — "<1 min" / "<1 min"
- `session.pause` — "Pause" / "Pausar"
- `session.resume` — "Resume" / "Retomar"
- `session.mapstyle.a11y` — "Change map style" / "Alterar estilo do mapa"

Existing keys preserved: `session.end`, `session.tunnel.on`, `session.tunnel.off`, `session.fit`, `session.progress`, `session.music.a11y`, `common.back`.

### Accessibility

- `SessionTitleLabel` — `.accessibilityAddTraits(.isHeader)`.
- Each `SessionControlButton` — `accessibilityLabel` (the button name) + `accessibilityValue` ("on" / "off" / "disabled") for toggles.
- `SessionMetricTile` — `.accessibilityElement(children: .combine)`, combined label like "Time remaining, 259 minutes".
- Existing labels on Music, Tunnel, Follow, End preserved.

### Removed today

- `topBar` private view (routeRow + ticket code).
- `bottomBar` + `tunnelToggle` + `fitToggle` private views (replaced by control pills).
- `countdownBlock` (CountdownLabel moves to a metric tile; the giant center number goes away).
- Inline `musicButton` body (moves to `SessionMusicMenu`).
- Inline `showEndConfirm` state + dialog (moves to `SessionEndButton`).

`SessionView`'s body shrinks to ~60–80 lines of layout, no inline subview definitions.

## Phase 2 — Real pause

### Ticket model

Add two SwiftData properties:

- `pausedAt: Date?` — when the current pause began. `nil` = not currently paused.
- `accumulatedPause: TimeInterval` — sum of all completed pause intervals from prior pause/resume cycles. Default `0`.

Both default to safe values, so existing tickets read back as never-paused without migration code. SwiftData handles the schema bump automatically.

### SessionViewModel changes

- `var isPaused: Bool { ticket.pausedAt != nil }`
- `var currentPauseSlice: TimeInterval { isPaused ? max(0, now.timeIntervalSince(ticket.pausedAt!)) : 0 }`
- `elapsed` rewritten:

  ```swift
  max(0, now.timeIntervalSince(ticket.departDate) - ticket.accumulatedPause - currentPauseSlice)
  ```

- `togglePause()`:
  - If `!isPaused`: set `ticket.pausedAt = .now`, persist.
  - If `isPaused`: add `now - pausedAt` to `accumulatedPause`, set `pausedAt = nil`, persist.
- `start()` / `refresh()` continue to tick — derived properties now reflect pause naturally. While paused: `progress` freezes, `trainCoordinate` freezes, `remaining*` text freezes.

### SessionStore

Add `updatePauseState(ticket:pausedAt:accumulatedPause:)` that mutates the ticket and saves atomically. Mirrors the existing update API shape.

### Background / foreground

No extra code needed. Because `pausedAt` and `accumulatedPause` persist, the formula self-corrects on scenePhase changes. Pausing then closing the app for hours: on relaunch, the formula still subtracts the live `currentPauseSlice`, so the contador stays frozen at the same value it had when the user paused.

Edge cases:

- Pause with 1s left → resume → completes normally. `isArrived` triggers `onArrive` as before.
- Pause and never resume → session stays frozen indefinitely. No auto-cancel. User can `End` manually at any time. Ledger does not credit an un-completed session — falls out of existing rules.
- Background while paused → on foreground, `refresh()` recomputes, contador still frozen. No drift.

### UI changes (Phase 2)

- Pause button in left pill becomes **active**, no longer `disabled`.
- Icon swaps based on state: `pause.fill` (session running, button idle) ↔ `play.fill` (session paused, button active/white).
- When `isPaused`: a subtle dim overlay (≈30% black) is added on top of `RouteMapView` (below all chrome) to reinforce "everything stopped". Animated in/out with `.easeInOut(duration: 0.3)`.
- Title, control pills, end button, and metric tiles remain at full opacity above the dim — they stay legible and interactive.

### Streak / Ledger

No changes. A paused-and-resumed session that reaches `remaining <= 0` triggers `onArrive` and credits as today. A paused-and-never-resumed session never reaches `remaining <= 0` — falls out naturally.

## Testing

### Phase 1

- Manual: create a 1-minute ticket → confirm title, metrics tick down, pílulas respond, Tunnel toggle inverts color, Map style menu functions, End presents confirmation, animations play on appear.
- Preview snapshots of `SessionView` in three states (Tunnel off / Tunnel on / Follow off) across iPhone 15 Pro, 15 Pro Max, SE.
- No unit-test changes (SessionViewModel logic untouched aside from the `remainingMinutesText` formatter).
- A formatter unit test: `remainingMinutesText` returns "<1 min" for 30s, "1 min" for 60s, "259 min" for 259*60s.

### Phase 2

- Migration check: open an existing ticket (no new fields) → `isPaused` reads false, `accumulatedPause` reads 0.
- Toggle pause / resume / pause / resume → `accumulatedPause` accumulates correctly, contador freezes and unfreezes.
- Background scenario: pause → close app → reopen after 30s → metrics reflect 30s of pause, not 30s of progress.
- Pause with 1s left → resume → completes normally.
- Pause and never resume → app reopened after 1h → still paused, contador unchanged.
- Unit test on `SessionViewModel.elapsed` with mocked `now` and various pause states.

## Accessibility & i18n summary

- All new buttons and tiles carry localized `accessibilityLabel`/`accessibilityValue`.
- Title gets header trait.
- New keys land in `Localizable.xcstrings` (English + Portuguese).
- VoiceOver traversal order: title → end → left pill (top→bottom) → right pill (top→bottom) → time tile → distance tile.

## Rollout

- Phase 1 ships as a single PR. No feature flag.
- Phase 2 ships as a single PR after Phase 1 merges and is validated in app. No feature flag — SwiftData migration is safe via defaults.
- Each phase produces its own implementation plan via `superpowers:writing-plans`.

## Open items

None — all decisions resolved during brainstorming.
