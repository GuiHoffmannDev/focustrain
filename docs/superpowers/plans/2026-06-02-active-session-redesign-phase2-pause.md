# Active Session Redesign — Phase 2 (Real Pause) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Prereq:** Phase 1 plan (`2026-06-02-active-session-redesign-phase1-visual.md`) is shipped — the new `SessionView` chrome is in place, the Pause button exists in the left pill but is rendered in `.disabled` state.

**Goal:** Turn the disabled Pause button into a real, persisted pause. While paused, the timer freezes, the train freezes on the geodesic, and a subtle dim overlay on the map signals the paused state. The behavior must survive backgrounding, force-quit, and arbitrary wall-clock gaps.

**Architecture:** Add two new properties to the `Ticket` struct (`pausedAt`, `accumulatedPause`) with backwards-compatible JSON decode. Rewrite `SessionViewModel.elapsed` to subtract both `accumulatedPause` and the live `currentPauseSlice`. Add `togglePause()` on the view model that mutates the ticket via a new `SessionStore.updatePauseState(...)` method. Wire the Pause button in `SessionView` to call `togglePause()` and reflect the new state (icon swap + dim overlay).

**Tech Stack:** SwiftUI, `Codable` over JSON in `UserDefaults`, custom `init(from decoder:)` for backwards compatibility.

**Repo convention reminder:** New `.swift` files appear automatically in the target via synced groups; `project.pbxproj` is never edited by hand.

---

## File Structure

**Modify:**

- `FocusTrain/Core/Persistence/Ticket.swift` — Add `pausedAt`, `accumulatedPause`, custom `init(from:)`, and `isArrived(at:)` helper.
- `FocusTrain/Core/Persistence/SessionStore.swift` — Add `updatePauseState(pausedAt:accumulatedPause:)`, make `phase` pause-aware via `isArrived(at:)`.
- `FocusTrain/ContentView.swift` — Update `RidePresenter` init to use `ticket.isArrived()` instead of comparing against `arrivalDate` directly.
- `FocusTrain/Features/FocusSession/ViewModels/SessionViewModel.swift` — Update `elapsed`, add `isPaused`, add `togglePause()`.
- `FocusTrain/Features/FocusSession/Views/SessionView.swift` — Activate the Pause button (icon swap + state) and add the paused dim overlay over the map.

**Create:** none — Phase 2 is all wiring on top of Phase 1's component vocabulary.

---

## Task 1: Extend `Ticket` with paused-state fields

**Files:**

- Modify: `FocusTrain/Core/Persistence/Ticket.swift`

- [ ] **Step 1: Replace the file**

Overwrite `Ticket.swift` with:

```swift
import Foundation

/// A snapshot of an in-progress focus journey. Persisted as JSON in
/// `UserDefaults` so a session can be resumed after backgrounding or a
/// force-quit. The optional `pausedAt` + accumulated pause budget let
/// the live `elapsed` recompute correctly when the app re-enters
/// foreground after a pause.
struct Ticket: Codable, Equatable, Hashable {
    var scenario: String        // FocusScenario.rawValue
    var fromCode: String
    var fromCity: String
    var toCode: String
    var toCity: String
    var fromLat: Double
    var fromLon: Double
    var toLat: Double
    var toLon: Double
    var departDate: Date        // anchor — elapsed time is recomputed on relaunch
    var durationMinutes: Int
    var mapStyle: String        // MapStyle.rawValue
    var code: String            // e.g. "FT-7K2Q"
    var seatCode: String?       // e.g. "01C" — picked at SeatPicker stage
    var focusMode: String?      // FocusMode.rawValue or custom preset name

    // MARK: - Pause state (new in Phase 2)

    /// When the current pause began. `nil` means the session is running.
    var pausedAt: Date? = nil

    /// Sum of every prior pause interval already consumed by the session.
    /// Does NOT include the currently-open pause (if any) — that slice is
    /// computed live from `pausedAt`.
    var accumulatedPause: TimeInterval = 0

    // MARK: - Derived

    /// Scheduled arrival on the wall clock if the user never pauses.
    /// Pause does NOT shift this value — it represents the original
    /// promise on the boarding pass. The pause-aware "is this session
    /// actually over?" decision lives in `isArrived(at:)`.
    var arrivalDate: Date {
        departDate.addingTimeInterval(TimeInterval(durationMinutes) * 60)
    }

    /// Pause-aware completion check. Subtracts both the budget of prior
    /// closed pauses and the open pause slice (if any) from wall-clock
    /// elapsed before comparing against `totalDuration`. Use this anywhere
    /// you previously compared `Date.now >= arrivalDate`.
    func isArrived(at now: Date = .now) -> Bool {
        let currentPauseSlice = pausedAt.map { max(0, now.timeIntervalSince($0)) } ?? 0
        let elapsed = max(
            0,
            now.timeIntervalSince(departDate) - accumulatedPause - currentPauseSlice
        )
        return elapsed >= totalDuration
    }

    var totalDuration: TimeInterval {
        TimeInterval(durationMinutes) * 60
    }

    static func makeCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        let suffix = String((0..<4).map { _ in chars.randomElement()! })
        return "FT-\(suffix)"
    }

    // MARK: - Backwards-compatible decode

    /// Auto-synthesized decode would throw if `accumulatedPause` is missing
    /// from the JSON stored on disk for a pre-Phase-2 session. This custom
    /// initializer defaults the new fields so existing tickets decode cleanly.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        scenario          = try c.decode(String.self, forKey: .scenario)
        fromCode          = try c.decode(String.self, forKey: .fromCode)
        fromCity          = try c.decode(String.self, forKey: .fromCity)
        toCode            = try c.decode(String.self, forKey: .toCode)
        toCity            = try c.decode(String.self, forKey: .toCity)
        fromLat           = try c.decode(Double.self, forKey: .fromLat)
        fromLon           = try c.decode(Double.self, forKey: .fromLon)
        toLat             = try c.decode(Double.self, forKey: .toLat)
        toLon             = try c.decode(Double.self, forKey: .toLon)
        departDate        = try c.decode(Date.self,   forKey: .departDate)
        durationMinutes   = try c.decode(Int.self,    forKey: .durationMinutes)
        mapStyle          = try c.decode(String.self, forKey: .mapStyle)
        code              = try c.decode(String.self, forKey: .code)
        seatCode          = try c.decodeIfPresent(String.self, forKey: .seatCode)
        focusMode         = try c.decodeIfPresent(String.self, forKey: .focusMode)
        pausedAt          = try c.decodeIfPresent(Date.self,   forKey: .pausedAt)
        accumulatedPause  = try c.decodeIfPresent(TimeInterval.self, forKey: .accumulatedPause) ?? 0
    }

    /// Default memberwise-style initializer preserved for direct construction.
    init(
        scenario: String,
        fromCode: String,
        fromCity: String,
        toCode: String,
        toCity: String,
        fromLat: Double,
        fromLon: Double,
        toLat: Double,
        toLon: Double,
        departDate: Date,
        durationMinutes: Int,
        mapStyle: String,
        code: String,
        seatCode: String? = nil,
        focusMode: String? = nil,
        pausedAt: Date? = nil,
        accumulatedPause: TimeInterval = 0
    ) {
        self.scenario = scenario
        self.fromCode = fromCode
        self.fromCity = fromCity
        self.toCode = toCode
        self.toCity = toCity
        self.fromLat = fromLat
        self.fromLon = fromLon
        self.toLat = toLat
        self.toLon = toLon
        self.departDate = departDate
        self.durationMinutes = durationMinutes
        self.mapStyle = mapStyle
        self.code = code
        self.seatCode = seatCode
        self.focusMode = focusMode
        self.pausedAt = pausedAt
        self.accumulatedPause = accumulatedPause
    }
}
```

Notes:

- `arrivalDate` now includes `accumulatedPause` so any code that reads it (e.g. `SessionStore.phase`) treats a paused session as still "riding" until the user has *spent* the full duration awake.
- The explicit memberwise init preserves the call sites in `DurationPickerModel.makeTicket` and `BoardingPassView` previews without forcing them to pass the new fields.

- [ ] **Step 2: Build**

```bash
xcodebuild -project FocusTrain.xcodeproj -scheme FocusTrain -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build 2>&1 | tail -30
```

Expected: `BUILD SUCCEEDED`. If a Ticket constructor in `DurationPickerModel` or `BoardingPassView` previews fails to compile, that's a sign the explicit memberwise init signature drifted — verify each arg matches the call site.

- [ ] **Step 3: Smoke test backwards-compat decode**

Exercise the decode path against a ticket created before the new fields existed.

The reliable way: still on the Phase-1 commit (before applying Task 1 of Phase 2), build & run, start a session, then force-quit the simulator app — this writes a Phase-1-shape JSON ticket into `UserDefaults` under key `activeTicket`. Then apply Phase 2 Task 1 (this task), rebuild, and relaunch.

```bash
# Confirm there is a stored ticket before relaunching:
xcrun simctl get_app_container booted testapp.FocusTrain data 2>/dev/null
# Look for Library/Preferences/testapp.FocusTrain.plist; "activeTicket" key should be present.
```

After relaunch, the active-ride screen should restore without crashing, and the contador should show the correct remaining time. If the app crashes on launch with a `DecodingError`, the custom `init(from:)` is wrong — re-check it against the JSON keys printed in the plist.

- [ ] **Step 4: Commit**

```bash
git add FocusTrain/Core/Persistence/Ticket.swift
git commit -m "feat(ticket): add pausedAt + accumulatedPause with bwd-compat decode"
```

---

## Task 2: Add `SessionStore.updatePauseState(...)` and make `phase` pause-aware

**Files:**

- Modify: `FocusTrain/Core/Persistence/SessionStore.swift`

- [ ] **Step 1: Add the method**

Insert immediately after `updateMapStyle` (from Phase 1):

```swift
/// Persists pause-state changes on the active ticket. Used by
/// `SessionViewModel.togglePause()` so the choice survives backgrounding.
func updatePauseState(pausedAt: Date?, accumulatedPause: TimeInterval) {
    guard var ticket = activeTicket else { return }
    ticket.pausedAt = pausedAt
    ticket.accumulatedPause = accumulatedPause
    activeTicket = ticket
}
```

- [ ] **Step 2: Make `phase` pause-aware via `Ticket.isArrived(at:)`**

Find the existing `phase` computed property (around line 26):

```swift
var phase: Phase {
    guard let ticket = activeTicket else { return .idle }
    return Date.now >= ticket.arrivalDate ? .arrived : .riding
}
```

Replace with:

```swift
var phase: Phase {
    guard let ticket = activeTicket else { return .idle }
    return ticket.isArrived() ? .arrived : .riding
}
```

`isArrived(at:)` was added on `Ticket` in Task 1 and already encapsulates
the pause-aware elapsed math.

- [ ] **Step 3: Patch `ContentView.RidePresenter` init**

Open `FocusTrain/ContentView.swift` and find line 156:

```swift
_stage = State(initialValue: Date.now >= ticket.arrivalDate ? .arrived : .riding)
```

Replace with:

```swift
_stage = State(initialValue: ticket.isArrived() ? .arrived : .riding)
```

This ensures that re-launching the app while a paused session is stored
does NOT short-circuit to the "arrived" stage just because wall-clock
time has rolled past the original scheduled `arrivalDate`.

- [ ] **Step 4: Build**

```bash
xcodebuild -project FocusTrain.xcodeproj -scheme FocusTrain -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build 2>&1 | tail -20
```

Expected: `BUILD SUCCEEDED`.

- [ ] **Step 5: Commit**

```bash
git add FocusTrain/Core/Persistence/SessionStore.swift FocusTrain/ContentView.swift
git commit -m "feat(session): pause-aware arrival check in store + RidePresenter"
```

---

## Task 3: Teach `SessionViewModel` about pause

**Files:**

- Modify: `FocusTrain/Features/FocusSession/ViewModels/SessionViewModel.swift`

- [ ] **Step 1: Inject a `SessionStore` reference**

`SessionViewModel` currently does not have a handle on `SessionStore`. The view passes it in via Environment. Update the `init` so the model can persist pause state.

Replace the `init`:

```swift
init(ticket: Ticket) {
    self.ticket = ticket
}
```

with:

```swift
init(ticket: Ticket, store: SessionStore? = nil) {
    self.ticket = ticket
    self.store = store
}
```

And add a stored property under `let ticket: Ticket`:

```swift
/// Optional persistence sink for pause state. When nil, `togglePause`
/// still mutates `ticket` in memory but does not survive a relaunch.
weak var store: SessionStore?
```

Wait — `SessionStore` is a class, but `weak` requires anyObject and `final class` is fine. Use `weak var` to avoid retain cycles since the view owns the store via Environment.

- [ ] **Step 2: Make `ticket` mutable**

Change:

```swift
let ticket: Ticket
```

to:

```swift
private(set) var ticket: Ticket
```

This lets `togglePause()` mutate `pausedAt` and `accumulatedPause` in place.

- [ ] **Step 3: Add `isPaused` + `currentPauseSlice`**

Insert after `elapsed` (around current line 36):

```swift
/// True while the session is in a paused state.
var isPaused: Bool { ticket.pausedAt != nil }

/// Seconds spent inside the currently-open pause (zero if not paused).
var currentPauseSlice: TimeInterval {
    guard let pausedAt = ticket.pausedAt else { return 0 }
    return max(0, now.timeIntervalSince(pausedAt))
}
```

- [ ] **Step 4: Rewrite `elapsed`**

Replace the existing:

```swift
var elapsed: TimeInterval {
    max(0, now.timeIntervalSince(ticket.departDate))
}
```

with:

```swift
var elapsed: TimeInterval {
    let raw = now.timeIntervalSince(ticket.departDate)
        - ticket.accumulatedPause
        - currentPauseSlice
    return max(0, raw)
}
```

- [ ] **Step 5: Add `togglePause()`**

Insert after the `scenario` / `mapStyle` block (near the bottom of the file):

```swift
/// Flip between running and paused. Persists immediately via `store`
/// so the state survives backgrounding and force-quit.
func togglePause() {
    if let pausedAt = ticket.pausedAt {
        // Close the current pause window: roll its duration into
        // the accumulated budget and clear pausedAt.
        let slice = max(0, now.timeIntervalSince(pausedAt))
        ticket.accumulatedPause += slice
        ticket.pausedAt = nil
    } else {
        ticket.pausedAt = now
    }
    store?.updatePauseState(
        pausedAt: ticket.pausedAt,
        accumulatedPause: ticket.accumulatedPause
    )
}
```

- [ ] **Step 6: Build**

```bash
xcodebuild -project FocusTrain.xcodeproj -scheme FocusTrain -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build 2>&1 | tail -30
```

Expected: `BUILD SUCCEEDED`. The view's `_model = State(initialValue: SessionViewModel(ticket: ticket))` still compiles because `store` has a default of `nil`. Wiring the real `store` happens in Task 4.

- [ ] **Step 7: Commit**

```bash
git add FocusTrain/Features/FocusSession/ViewModels/SessionViewModel.swift
git commit -m "feat(session): teach SessionViewModel real pause semantics"
```

---

## Task 4: Wire the Pause button in `SessionView`

**Files:**

- Modify: `FocusTrain/Features/FocusSession/Views/SessionView.swift`

- [ ] **Step 1: Pass the `SessionStore` into the model on appear**

The view already has `@Environment(SessionStore.self) private var session`. Hook it up to the model in `onAppear`.

Find this `onAppear` block (post-Phase-1):

```swift
.onAppear {
    model.onArrive = onArrive
    model.start()
    if UserDefaults.standard.bool(forKey: "quietCarriageEnabled") {
        tunnel.enter()
    }
    withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
        appeared = true
    }
}
```

Replace with:

```swift
.onAppear {
    model.store = session
    model.onArrive = onArrive
    model.start()
    if UserDefaults.standard.bool(forKey: "quietCarriageEnabled") {
        tunnel.enter()
    }
    withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
        appeared = true
    }
}
```

- [ ] **Step 2: Replace the disabled Pause button with a real one**

Find this block inside the left `SessionControlPill` (added in Phase 1):

```swift
SessionControlButton(
    systemName: "pause.fill",
    state: .disabled,
    accessibilityLabel: NSLocalizedString("session.pause", comment: ""),
    accessibilityValue: NSLocalizedString("session.pause.disabled.a11y", comment: "")
) {}
```

Replace with:

```swift
SessionControlButton(
    systemName: model.isPaused ? "play.fill" : "pause.fill",
    state: model.isPaused ? .active : .idle,
    accessibilityLabel: NSLocalizedString(
        model.isPaused ? "session.resume" : "session.pause",
        comment: ""
    ),
    accessibilityValue: model.isPaused ? "paused" : "running"
) {
    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
        model.togglePause()
    }
}
```

- [ ] **Step 3: Add the paused dim overlay above `RouteMapView`**

Find the top of the `ZStack` body, where `RouteMapView` and `scrim` and `TunnelHero` are layered. Insert a dim overlay between `RouteMapView` and `scrim`:

```swift
RouteMapView(
    from: model.fromCoordinate,
    to: model.toCoordinate,
    fraction: model.progress,
    style: mapStyle,
    showLabels: UserDefaults.standard.bool(forKey: "mapShowLabels"),
    follow: followTrain
)
.ignoresSafeArea()

// Paused-state dim. Subtle, sits above the map but below all chrome.
FT.Palette.black
    .opacity(model.isPaused ? 0.3 : 0)
    .ignoresSafeArea()
    .allowsHitTesting(false)
    .animation(.easeInOut(duration: 0.3), value: model.isPaused)

scrim

TunnelHero(isActive: tunnel.isActive)
    .animation(.easeInOut(duration: 0.5), value: tunnel.isActive)
```

- [ ] **Step 4: Build**

```bash
xcodebuild -project FocusTrain.xcodeproj -scheme FocusTrain -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build 2>&1 | tail -20
```

Expected: `BUILD SUCCEEDED`.

- [ ] **Step 5: Commit**

```bash
git add FocusTrain/Features/FocusSession/Views/SessionView.swift
git commit -m "feat(session): activate Pause button + dim overlay while paused"
```

---

## Task 5: Manual verification

**Files:** none.

- [ ] **Step 1: Happy path**

Run the app on iPhone 15 Pro simulator. Start a 2-minute session.

1. Tap Pause (left pill, top button).
   - Expect: icon flips to `play.fill`, button turns solid white, map dims by ~30%, contador stops counting, train stops moving.
2. Wait ~10s. Verify the contador value is unchanged.
3. Tap the button again (now Resume).
   - Expect: icon flips back to `pause.fill`, button returns to translucent dark, dim fades out, contador resumes from where it left off, train resumes moving.

- [ ] **Step 2: Backgrounding while paused**

Start a 2-minute session. Pause. Press the simulator's Home button (Cmd+Shift+H). Wait 30s. Reopen the app.

- Expect: still paused, contador unchanged from when you paused, dim still on, button still in resume state. Tap to resume — contador continues without "swallowing" the 30s.

- [ ] **Step 3: Force-quit while paused**

Start a 2-minute session. Pause. Force-quit the app (in simulator: Cmd+Shift+H twice, swipe up the app card; or stop debugging in Xcode and relaunch).

- Expect: on relaunch the active-ride screen restores, still paused, contador unchanged. Resume works normally.

- [ ] **Step 4: Multiple pause cycles**

Start a 5-minute session. Pause for ~20s, resume for ~20s, pause for ~20s, resume.

- Expect: each cycle of pause+resume rolls cleanly. The contador reflects only the time spent un-paused. After two ~20s pauses you have effectively added ~40s to the wall-clock arrival time.

- [ ] **Step 5: Pause near the end**

Start a 1-minute session. Wait until ~5s remain. Pause.

- Expect: contador freezes at ~5s. Resume after 30s. Contador continues from 5s and reaches 0 normally, firing `onArrive`.

- [ ] **Step 6: Pause and never resume**

Start a 1-minute session. Pause immediately. Leave the app open for >2 minutes.

- Expect: contador stays frozen. App never auto-completes. No `onArrive` fires. Tapping End still works and routes through the normal confirmation flow.

- [ ] **Step 7: VoiceOver labels**

Enable VoiceOver. Focus the Pause button.

- Expect: when running, reads "Pause, button, running". When paused, reads "Resume, button, paused".

- [ ] **Step 8: Final commit (only if cleanup needed)**

```bash
git add -p
git commit -m "fix(session): <specific cleanup>"
```

---

## Done criteria for Phase 2

- All 5 tasks complete and committed.
- `xcodebuild ... build` succeeds.
- Manual smoke tests in Task 5 all pass.
- Existing tickets (from before Phase 2) load without crashing — backwards-compat decode confirmed.
- A paused session survives backgrounding, force-quit, and arbitrary delays without leaking wall-clock time into `elapsed`.
