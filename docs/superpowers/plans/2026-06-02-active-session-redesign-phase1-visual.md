# Active Session Redesign — Phase 1 (Visual) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild `SessionView` chrome to a flight-tracker layout — floating destination title at top, two vertical control pills hugging the side edges, two small metric tiles in the bottom corners. The map and train become the heroes. No behavioral changes to the session timer; Pause stays disabled in the left pill until Phase 2.

**Architecture:** Decompose the existing monolithic `SessionView` into six small, reusable components (4 in `Core/DesignSystem`, 2 in `Features/FocusSession/Views/Components`). The view becomes a thin `ZStack` of `RouteMapView` + scrim + `TunnelHero` + four positioned chrome groups. Add one new formatter to `SessionViewModel` and one new method to `SessionStore`. Layout positioning uses safe-area-respecting padding and `FT.Layout.sideMargin`.

**Tech Stack:** SwiftUI, `@Observable` view models, `@AppStorage`-style JSON persistence via `SessionStore`, FT design tokens (`FT.Palette`, `FT.Typography`, `FT.Layout`), SF Symbols, MapKit via `RouteMapView`.

**Repo convention reminder:** `.swift` files in this repo live in **Xcode synced file groups** — new files are picked up automatically and `project.pbxproj` is never edited by hand (per CLAUDE memory `project_synced_file_groups.md`). The repo has no unit-test target today; verification uses SwiftUI `#Preview` blocks + manual simulator smoke tests rather than XCTest.

---

## File Structure

**Create:**

- `FocusTrain/Core/DesignSystem/Components/SessionTitleLabel.swift` — Outlined white text for "label-on-map" titles.
- `FocusTrain/Core/DesignSystem/Components/SessionControlButton.swift` — 40pt circular control with idle / active / disabled states.
- `FocusTrain/Core/DesignSystem/Components/SessionControlPill.swift` — Vertical capsule container that stacks `SessionControlButton`s.
- `FocusTrain/Core/DesignSystem/Components/SessionMetricTile.swift` — Small label + large value tile for corner metrics.
- `FocusTrain/Features/FocusSession/Views/Components/SessionEndButton.swift` — Isolated top-right X button, owns its own confirmation dialog state.
- `FocusTrain/Features/FocusSession/Views/Components/SessionMusicMenu.swift` — Wraps the `FocusScenario` `Menu`, owns the `session.updateScenario` side-effect.

**Modify:**

- `FocusTrain/Features/FocusSession/ViewModels/SessionViewModel.swift` — Add `remainingMinutesText` formatter.
- `FocusTrain/Core/Persistence/SessionStore.swift` — Add `updateMapStyle(_:)` method (mirrors `updateScenario`).
- `FocusTrain/Features/FocusSession/Views/SessionView.swift` — Replace the entire body composition with the new layout.
- `FocusTrain/Resources/Localizable.xcstrings` — Add new keys: `session.time.remaining`, `session.distance.remaining` (verify), `session.minutes.unit`, `session.minutes.lt1`, `session.pause`, `session.resume`, `session.mapstyle.a11y`.

---

## Task 1: Add `remainingMinutesText` to `SessionViewModel`

**Files:**

- Modify: `FocusTrain/Features/FocusSession/ViewModels/SessionViewModel.swift` (insert after `remainingText`, around line 60)

- [ ] **Step 1: Add the formatter**

Insert this computed property just after the existing `remainingText` (line 59):

```swift
/// Bottom-tile copy: "N min" for ≥1 minute, "<1 min" otherwise.
/// Always uses minutes — no MM:SS — because the tile is small.
var remainingMinutesText: String {
    if remaining < 60 {
        return NSLocalizedString("session.minutes.lt1", comment: "Shown when under one minute remains")
    }
    let minutes = Int((remaining / 60).rounded())
    let unit = NSLocalizedString("session.minutes.unit", comment: "Short minutes unit")
    return "\(minutes) \(unit)"
}
```

- [ ] **Step 2: Build to verify it compiles**

Run in repo root:

```bash
xcodebuild -project FocusTrain.xcodeproj -scheme FocusTrain -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build 2>&1 | tail -20
```

Expected: `BUILD SUCCEEDED`.

- [ ] **Step 3: Commit**

```bash
git add FocusTrain/Features/FocusSession/ViewModels/SessionViewModel.swift
git commit -m "feat(session): add remainingMinutesText formatter"
```

---

## Task 2: Add `SessionStore.updateMapStyle(_:)`

**Files:**

- Modify: `FocusTrain/Core/Persistence/SessionStore.swift` (insert after `updateScenario`, around line 46)

- [ ] **Step 1: Add the method**

Insert immediately after `updateScenario` (after the closing brace at line 46):

```swift
/// Updates only the map style on the active ticket. Used by the in-ride
/// map-style selector so the choice survives backgrounding and flows into
/// the saved Journey at arrival. Mirrors `updateScenario`.
func updateMapStyle(_ style: MapStyle) {
    guard var ticket = activeTicket, ticket.mapStyle != style.rawValue else { return }
    ticket.mapStyle = style.rawValue
    activeTicket = ticket
}
```

- [ ] **Step 2: Build to verify it compiles**

```bash
xcodebuild -project FocusTrain.xcodeproj -scheme FocusTrain -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build 2>&1 | tail -20
```

Expected: `BUILD SUCCEEDED`.

- [ ] **Step 3: Commit**

```bash
git add FocusTrain/Core/Persistence/SessionStore.swift
git commit -m "feat(session): add SessionStore.updateMapStyle"
```

---

## Task 3: Create `SessionTitleLabel` component

**Files:**

- Create: `FocusTrain/Core/DesignSystem/Components/SessionTitleLabel.swift`

- [ ] **Step 1: Write the component**

```swift
import SwiftUI

/// Large outlined white title made to sit over an arbitrary map background.
/// The outline is approximated with eight directional shadowed copies so the
/// text is legible against both dark and bright map regions.
struct SessionTitleLabel: View {
    let text: String

    private static let outlineColor = Color.black.opacity(0.85)
    private static let outlineRadius: CGFloat = 1.5
    private static let outlineOffsets: [(CGFloat, CGFloat)] = [
        (-1.5, 0), (1.5, 0), (0, -1.5), (0, 1.5),
        (-1.0, -1.0), (1.0, -1.0), (-1.0, 1.0), (1.0, 1.0),
    ]

    var body: some View {
        ZStack {
            ForEach(0..<Self.outlineOffsets.count, id: \.self) { i in
                let (dx, dy) = Self.outlineOffsets[i]
                Text(text)
                    .font(.system(size: 28, weight: .bold, design: .default))
                    .foregroundStyle(Self.outlineColor)
                    .offset(x: dx, y: dy)
            }
            Text(text)
                .font(.system(size: 28, weight: .bold, design: .default))
                .foregroundStyle(FT.Palette.white)
        }
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
        .accessibilityAddTraits(.isHeader)
    }
}

#Preview("Single line") {
    ZStack {
        FT.Palette.bgElevated.ignoresSafeArea()
        SessionTitleLabel(text: "Ricardo Flores Magón")
    }
}

#Preview("Wrap") {
    ZStack {
        FT.Palette.bgElevated.ignoresSafeArea()
        SessionTitleLabel(text: "São Paulo Estação da Luz Central")
            .padding(.horizontal, 40)
    }
}
```

- [ ] **Step 2: Build and verify previews render**

```bash
xcodebuild -project FocusTrain.xcodeproj -scheme FocusTrain -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build 2>&1 | tail -20
```

Expected: `BUILD SUCCEEDED`. Open the file in Xcode and confirm both previews render: white bold text with a dark outline on the dark background.

- [ ] **Step 3: Commit**

```bash
git add FocusTrain/Core/DesignSystem/Components/SessionTitleLabel.swift
git commit -m "feat(ds): add SessionTitleLabel for outlined map titles"
```

---

## Task 4: Create `SessionControlButton` component

**Files:**

- Create: `FocusTrain/Core/DesignSystem/Components/SessionControlButton.swift`

- [ ] **Step 1: Write the component**

```swift
import SwiftUI

/// 40pt circular control used inside `SessionControlPill`. Three states:
///   • idle     — translucent dark fill, white glyph.
///   • active   — solid white fill, ink glyph. (Toggle-on visual.)
///   • disabled — idle styling at 0.4 opacity, hit testing off.
struct SessionControlButton: View {
    enum State {
        case idle
        case active
        case disabled
    }

    let systemName: String
    let state: State
    let action: () -> Void
    var accessibilityLabel: String
    var accessibilityValue: String? = nil

    init(
        systemName: String,
        state: State,
        accessibilityLabel: String,
        accessibilityValue: String? = nil,
        action: @escaping () -> Void
    ) {
        self.systemName = systemName
        self.state = state
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityValue = accessibilityValue
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(glyphColor)
                .frame(width: 40, height: 40)
                .background(Circle().fill(backgroundFill))
                .overlay(Circle().stroke(strokeColor, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(state == .disabled)
        .opacity(state == .disabled ? 0.4 : 1.0)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(accessibilityValue ?? "")
    }

    private var glyphColor: Color {
        switch state {
        case .active:   return FT.Palette.ink
        case .idle:     return FT.Palette.white
        case .disabled: return FT.Palette.white
        }
    }

    private var backgroundFill: Color {
        switch state {
        case .active:   return FT.Palette.white
        case .idle:     return FT.Palette.black.opacity(0.5)
        case .disabled: return FT.Palette.black.opacity(0.5)
        }
    }

    private var strokeColor: Color {
        switch state {
        case .active:   return .clear
        case .idle:     return FT.Palette.textMuted.opacity(0.3)
        case .disabled: return FT.Palette.textMuted.opacity(0.3)
        }
    }
}

#Preview("States") {
    HStack(spacing: 12) {
        SessionControlButton(systemName: "moon", state: .idle, accessibilityLabel: "Tunnel") {}
        SessionControlButton(systemName: "moon.zzz.fill", state: .active, accessibilityLabel: "Tunnel") {}
        SessionControlButton(systemName: "pause.fill", state: .disabled, accessibilityLabel: "Pause") {}
    }
    .padding()
    .background(FT.Palette.bgElevated)
}
```

- [ ] **Step 2: Build and inspect preview**

```bash
xcodebuild -project FocusTrain.xcodeproj -scheme FocusTrain -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build 2>&1 | tail -20
```

Expected: `BUILD SUCCEEDED`. Preview should show three buttons: dark translucent, solid white, and dim translucent.

- [ ] **Step 3: Commit**

```bash
git add FocusTrain/Core/DesignSystem/Components/SessionControlButton.swift
git commit -m "feat(ds): add SessionControlButton with idle/active/disabled states"
```

---

## Task 5: Create `SessionControlPill` component

**Files:**

- Create: `FocusTrain/Core/DesignSystem/Components/SessionControlPill.swift`

- [ ] **Step 1: Write the component**

```swift
import SwiftUI

/// Vertical capsule container that stacks side-control buttons.
/// Used in pairs on the left and right edges of `SessionView`.
struct SessionControlPill<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 6) {
            content()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 6)
        .background(
            Capsule()
                .fill(FT.Palette.bgElevated.opacity(0.5))
        )
        .overlay(
            Capsule()
                .stroke(FT.Palette.textMuted.opacity(0.25), lineWidth: 1)
        )
    }
}

#Preview("Two buttons") {
    ZStack {
        FT.Palette.bgElevated.ignoresSafeArea()
        SessionControlPill {
            SessionControlButton(systemName: "pause.fill", state: .disabled, accessibilityLabel: "Pause") {}
            SessionControlButton(systemName: "music.note", state: .idle, accessibilityLabel: "Music") {}
        }
    }
}

#Preview("Three buttons") {
    ZStack {
        FT.Palette.bgElevated.ignoresSafeArea()
        SessionControlPill {
            SessionControlButton(systemName: "moon.zzz.fill", state: .active, accessibilityLabel: "Tunnel") {}
            SessionControlButton(systemName: "scope", state: .idle, accessibilityLabel: "Follow") {}
            SessionControlButton(systemName: "map", state: .idle, accessibilityLabel: "Map style") {}
        }
    }
}
```

- [ ] **Step 2: Build and inspect previews**

```bash
xcodebuild -project FocusTrain.xcodeproj -scheme FocusTrain -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build 2>&1 | tail -20
```

Expected: `BUILD SUCCEEDED`. Pills should render as elongated vertical capsules with 2 and 3 buttons stacked.

- [ ] **Step 3: Commit**

```bash
git add FocusTrain/Core/DesignSystem/Components/SessionControlPill.swift
git commit -m "feat(ds): add SessionControlPill vertical capsule container"
```

---

## Task 6: Create `SessionMetricTile` component

**Files:**

- Create: `FocusTrain/Core/DesignSystem/Components/SessionMetricTile.swift`

- [ ] **Step 1: Write the component**

```swift
import SwiftUI

/// Small uppercase muted label above a large white value.
/// Used in the bottom corners of `SessionView` for time and distance.
struct SessionMetricTile: View {
    let label: String
    let value: String
    var alignment: HorizontalAlignment = .leading

    var body: some View {
        VStack(alignment: alignment, spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .semibold, design: .default))
                .tracking(0.6)
                .textCase(.uppercase)
                .foregroundStyle(FT.Palette.textMuted)

            Text(value)
                .font(.system(size: 28, weight: .bold, design: .default))
                .foregroundStyle(FT.Palette.white)
                .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label), \(value)")
    }
}

#Preview {
    HStack {
        SessionMetricTile(label: "Time Remaining", value: "259 min", alignment: .leading)
        Spacer()
        SessionMetricTile(label: "Distance Remaining", value: "3.268 km", alignment: .trailing)
    }
    .padding()
    .background(FT.Palette.bgElevated)
}
```

- [ ] **Step 2: Build and inspect preview**

```bash
xcodebuild -project FocusTrain.xcodeproj -scheme FocusTrain -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build 2>&1 | tail -20
```

Expected: `BUILD SUCCEEDED`. Preview shows two tiles aligned to opposite edges, label small uppercase gray, value large white bold.

- [ ] **Step 3: Commit**

```bash
git add FocusTrain/Core/DesignSystem/Components/SessionMetricTile.swift
git commit -m "feat(ds): add SessionMetricTile for corner metrics"
```

---

## Task 7: Create `SessionEndButton` component

**Files:**

- Create: `FocusTrain/Features/FocusSession/Views/Components/SessionEndButton.swift`

- [ ] **Step 1: Write the component**

```swift
import SwiftUI

/// Isolated top-right X. Owns its own confirmation-dialog state so the
/// parent `SessionView` body stays clean.
struct SessionEndButton: View {
    var onEnd: () -> Void

    @State private var showConfirm = false

    var body: some View {
        Button {
            showConfirm = true
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(FT.Palette.white)
                .frame(width: 40, height: 40)
                .background(Circle().fill(FT.Palette.black.opacity(0.5)))
                .overlay(Circle().stroke(FT.Palette.textMuted.opacity(0.3), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(NSLocalizedString("session.end", comment: "End the ride")))
        .confirmationDialog(
            NSLocalizedString("session.end", comment: ""),
            isPresented: $showConfirm,
            titleVisibility: .visible
        ) {
            Button(NSLocalizedString("session.end", comment: ""), role: .destructive, action: onEnd)
            Button(NSLocalizedString("common.back", comment: ""), role: .cancel) {}
        }
    }
}

#Preview {
    ZStack {
        FT.Palette.bgElevated.ignoresSafeArea()
        SessionEndButton(onEnd: {})
    }
}
```

- [ ] **Step 2: Build**

```bash
xcodebuild -project FocusTrain.xcodeproj -scheme FocusTrain -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build 2>&1 | tail -20
```

Expected: `BUILD SUCCEEDED`.

- [ ] **Step 3: Commit**

```bash
git add FocusTrain/Features/FocusSession/Views/Components/SessionEndButton.swift
git commit -m "feat(session): extract SessionEndButton with self-owned dialog"
```

---

## Task 8: Create `SessionMusicMenu` component

**Files:**

- Create: `FocusTrain/Features/FocusSession/Views/Components/SessionMusicMenu.swift`

- [ ] **Step 1: Write the component**

```swift
import SwiftUI

/// Wraps the in-ride music/scenario picker. Owns the `session.updateScenario`
/// side-effect so the parent view doesn't need to thread it.
struct SessionMusicMenu: View {
    @Binding var scenario: FocusScenario
    var onSelect: (FocusScenario) -> Void

    var body: some View {
        Menu {
            ForEach(FocusScenario.allCases) { option in
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    scenario = option
                    onSelect(option)
                } label: {
                    Label {
                        Text(LocalizedStringKey(option.displayKey))
                    } icon: {
                        Image(systemName: scenario == option ? "checkmark" : option.symbol)
                    }
                }
            }
        } label: {
            Image(systemName: "music.note")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(FT.Palette.white)
                .frame(width: 40, height: 40)
                .background(Circle().fill(FT.Palette.black.opacity(0.5)))
                .overlay(Circle().stroke(FT.Palette.textMuted.opacity(0.3), lineWidth: 1))
        }
        .accessibilityLabel(Text(NSLocalizedString("session.music.a11y", comment: "")))
    }
}
```

Notes:

- This component does NOT use `SessionControlButton` because `Menu` requires a `View` label, not a tap handler.
- Its visual size (40pt circle, black 0.5 fill, muted stroke) matches `SessionControlButton.idle` so it slots into a pill seamlessly.

- [ ] **Step 2: Build**

```bash
xcodebuild -project FocusTrain.xcodeproj -scheme FocusTrain -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build 2>&1 | tail -20
```

Expected: `BUILD SUCCEEDED`.

- [ ] **Step 3: Commit**

```bash
git add FocusTrain/Features/FocusSession/Views/Components/SessionMusicMenu.swift
git commit -m "feat(session): extract SessionMusicMenu wrapper"
```

---

## Task 9: Add new localization keys

**Files:**

- Modify: `FocusTrain/Resources/Localizable.xcstrings`

- [ ] **Step 1: Inspect existing keys**

Run:

```bash
grep -E '"session\.|"common\.back"' /Users/guilhermehoffmann/Desktop/Projects/FocusTrain/FocusTrain/Resources/Localizable.xcstrings | head -40
```

Expected: confirms which of these already exist. The keys to ADD (only if missing) are:

- `session.time.remaining` → English "Time Remaining" / Portuguese "Tempo Restante"
- `session.distance.remaining` → English "Distance Remaining" / Portuguese "Distância Restante"
- `session.minutes.unit` → English "min" / Portuguese "min"
- `session.minutes.lt1` → English "<1 min" / Portuguese "<1 min"
- `session.pause` → English "Pause" / Portuguese "Pausar"
- `session.resume` → English "Resume" / Portuguese "Retomar"
- `session.mapstyle.a11y` → English "Change map style" / Portuguese "Alterar estilo do mapa"

- [ ] **Step 2: Add the keys**

Open `FocusTrain/Resources/Localizable.xcstrings` in Xcode's String Catalog editor. For each missing key above, click `+` to add a new key and provide the English and Portuguese translations. If editing as JSON, add entries inside the top-level `strings` object using the shape of an existing entry. Each entry has the form:

```json
"session.time.remaining" : {
  "localizations" : {
    "en" : { "stringUnit" : { "state" : "translated", "value" : "Time Remaining" } },
    "pt-BR" : { "stringUnit" : { "state" : "translated", "value" : "Tempo Restante" } }
  }
}
```

Use the locale codes already present in the file for the other entries (e.g. `pt-BR` vs `pt`). Do not invent new locales.

- [ ] **Step 3: Build**

```bash
xcodebuild -project FocusTrain.xcodeproj -scheme FocusTrain -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build 2>&1 | tail -20
```

Expected: `BUILD SUCCEEDED` and no missing-key warnings for the new keys.

- [ ] **Step 4: Commit**

```bash
git add FocusTrain/Resources/Localizable.xcstrings
git commit -m "i18n(session): add keys for redesigned active-session chrome"
```

---

## Task 10: Rewrite `SessionView` with the new layout

This task replaces the entire body of `SessionView`. It removes `topBar`, `bottomBar`, `tunnelToggle`, `fitToggle`, `countdownBlock`, `musicButton`, `routeRow`, and the inline `showEndConfirm` state. It keeps `RouteMapView`, `scrim`, `TunnelHero`, and the existing `start/stop/refresh` lifecycle wiring.

**Files:**

- Modify: `FocusTrain/Features/FocusSession/Views/SessionView.swift`

- [ ] **Step 1: Replace the file contents**

Overwrite `SessionView.swift` with:

```swift
import SwiftUI

/// The live ride: a full-screen geodesic map with a glowing train. Chrome
/// floats on top — destination title at the top, side control pills hugging
/// the edges, and tiny time/distance metric tiles in the bottom corners.
struct SessionView: View {
    let ticket: Ticket
    /// Fired once the journey's full duration has elapsed.
    var onArrive: () -> Void
    /// Fired when the traveller ends the ride early.
    var onEnd: () -> Void

    @State private var model: SessionViewModel
    @State private var tunnel = InAppTunnelController()
    @State private var followTrain = true
    @State private var appeared = false
    @State private var scenario: FocusScenario
    @State private var mapStyle: MapStyle

    @Environment(\.scenePhase) private var scenePhase
    @Environment(SessionStore.self) private var session

    init(ticket: Ticket, onArrive: @escaping () -> Void, onEnd: @escaping () -> Void) {
        self.ticket = ticket
        self.onArrive = onArrive
        self.onEnd = onEnd
        _model = State(initialValue: SessionViewModel(ticket: ticket))
        _scenario = State(initialValue: FocusScenario(rawValue: ticket.scenario) ?? .forest)
        _mapStyle = State(initialValue: MapStyle(rawValue: ticket.mapStyle) ?? .monochrome)
    }

    var body: some View {
        ZStack {
            RouteMapView(
                from: model.fromCoordinate,
                to: model.toCoordinate,
                fraction: model.progress,
                style: mapStyle,
                showLabels: UserDefaults.standard.bool(forKey: "mapShowLabels"),
                follow: followTrain
            )
            .ignoresSafeArea()

            scrim

            TunnelHero(isActive: tunnel.isActive)
                .animation(.easeInOut(duration: 0.5), value: tunnel.isActive)

            // Top: destination title (centered) + end button (top-right).
            VStack {
                ZStack {
                    SessionTitleLabel(text: destinationName)
                        .padding(.horizontal, 60) // leave room for end button
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : -16)

                    HStack {
                        Spacer()
                        SessionEndButton(onEnd: onEnd)
                            .opacity(appeared ? 1 : 0)
                    }
                }
                .padding(.top, 8)
                Spacer()
            }
            .padding(.horizontal, FT.Layout.sideMargin)

            // Left + right control pills, vertically centered on the screen.
            HStack {
                SessionControlPill {
                    SessionControlButton(
                        systemName: "pause.fill",
                        state: .disabled,
                        accessibilityLabel: NSLocalizedString("session.pause", comment: ""),
                        accessibilityValue: NSLocalizedString("session.pause.disabled.a11y", comment: "")
                    ) {}

                    SessionMusicMenu(
                        scenario: $scenario,
                        onSelect: { session.updateScenario($0) }
                    )
                }
                .opacity(appeared ? 1 : 0)
                .offset(x: appeared ? 0 : -30)

                Spacer()

                SessionControlPill {
                    SessionControlButton(
                        systemName: tunnel.isActive ? "moon.zzz.fill" : "moon",
                        state: tunnel.isActive ? .active : .idle,
                        accessibilityLabel: NSLocalizedString(
                            tunnel.isActive ? "session.tunnel.on" : "session.tunnel.off",
                            comment: ""
                        ),
                        accessibilityValue: tunnel.isActive ? "on" : "off"
                    ) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
                            tunnel.toggle()
                        }
                    }

                    SessionControlButton(
                        systemName: followTrain ? "scope" : "tram.fill",
                        state: followTrain ? .active : .idle,
                        accessibilityLabel: NSLocalizedString(
                            followTrain ? "session.fit" : "session.progress",
                            comment: ""
                        ),
                        accessibilityValue: followTrain ? "on" : "off"
                    ) {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
                            followTrain.toggle()
                        }
                    }

                    mapStyleMenu
                }
                .opacity(appeared ? 1 : 0)
                .offset(x: appeared ? 0 : 30)
            }
            .padding(.horizontal, FT.Layout.sideMargin)

            // Bottom: time + distance tiles.
            VStack {
                Spacer()
                HStack(alignment: .bottom) {
                    SessionMetricTile(
                        label: NSLocalizedString("session.time.remaining", comment: ""),
                        value: model.remainingMinutesText,
                        alignment: .leading
                    )
                    Spacer()
                    SessionMetricTile(
                        label: NSLocalizedString("session.distance.remaining", comment: ""),
                        value: model.remainingDistanceText,
                        alignment: .trailing
                    )
                }
                .padding(.bottom, 16)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 24)
            }
            .padding(.horizontal, FT.Layout.sideMargin)
        }
        .background(FT.Palette.black)
        .navigationBarBackButtonHidden(true)
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
        .onDisappear { model.stop() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { model.refresh() }
        }
    }

    // MARK: - Destination name

    private var destinationName: String {
        StationPool.station(forCode: ticket.toCode)?.city ?? ticket.toCode
    }

    // MARK: - Scrim

    private var scrim: some View {
        VStack {
            LinearGradient(
                colors: [FT.Palette.black.opacity(0.75), .clear],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 220)
            Spacer()
            LinearGradient(
                colors: [.clear, FT.Palette.black.opacity(0.85)],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 280)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    // MARK: - Map style menu

    private var mapStyleMenu: some View {
        Menu {
            ForEach(MapStyle.allCases) { option in
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    mapStyle = option
                    session.updateMapStyle(option)
                } label: {
                    Label {
                        Text(LocalizedStringKey(option.displayKey))
                    } icon: {
                        Image(systemName: mapStyle == option ? "checkmark" : option.symbol)
                    }
                }
            }
        } label: {
            Image(systemName: "map")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(FT.Palette.white)
                .frame(width: 40, height: 40)
                .background(Circle().fill(FT.Palette.black.opacity(0.5)))
                .overlay(Circle().stroke(FT.Palette.textMuted.opacity(0.3), lineWidth: 1))
        }
        .accessibilityLabel(Text(NSLocalizedString("session.mapstyle.a11y", comment: "")))
    }
}
```

Notes for the implementer:

- `MapStyle` is expected to be `Identifiable & CaseIterable` and to expose `displayKey: String` and `symbol: String`, mirroring `FocusScenario` (see `FocusScenario` in this repo). If `MapStyle` is not `CaseIterable` today, add `extension MapStyle: CaseIterable {}` in the same file as `MapStyle` (or a small extension under `Core/Map/`). If `displayKey` / `symbol` are missing, mirror them from `FocusScenario`. Make that change as a tiny separate commit before re-running the build below if needed — DO NOT silently change behavior.
- `session.pause.disabled.a11y` is a new key with copy "Coming soon" / "Em breve". Add it in `Localizable.xcstrings` here if missing.

- [ ] **Step 2: Patch up `MapStyle` if needed**

Run:

```bash
grep -n "enum MapStyle\|extension MapStyle\|displayKey\|symbol" /Users/guilhermehoffmann/Desktop/Projects/FocusTrain/FocusTrain/Core/Map/*.swift
```

If `MapStyle` lacks `CaseIterable`, `Identifiable`, `displayKey`, or `symbol`, add a small extension file `FocusTrain/Core/Map/MapStyle+Display.swift`:

```swift
import Foundation

extension MapStyle: CaseIterable, Identifiable {
    public var id: String { rawValue }

    var displayKey: String {
        "mapstyle.\(rawValue)"
    }

    var symbol: String {
        switch self {
        case .monochrome: return "moon"
        case .standard:   return "map"
        case .hybrid:     return "globe.americas"
        }
    }
}
```

And add the matching display keys (`mapstyle.monochrome`, `mapstyle.standard`, `mapstyle.hybrid`) to `Localizable.xcstrings` with English ("Monochrome" / "Standard" / "Hybrid") and Portuguese ("Monocromático" / "Padrão" / "Híbrido") values. If the file already provides equivalents under different names, use the existing ones and update `SessionView` to match.

- [ ] **Step 3: Add `session.pause.disabled.a11y` if missing**

In `Localizable.xcstrings`, add:

- `session.pause.disabled.a11y` → English "Coming soon" / Portuguese "Em breve"

- [ ] **Step 4: Build**

```bash
xcodebuild -project FocusTrain.xcodeproj -scheme FocusTrain -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build 2>&1 | tail -30
```

Expected: `BUILD SUCCEEDED`. Resolve any reference-to-removed-helper errors by deleting the corresponding now-orphaned helpers in `SessionView` (the rewritten file should already be complete — this is a fallback if the implementer missed a line).

- [ ] **Step 5: Commit**

```bash
git add FocusTrain/Features/FocusSession/Views/SessionView.swift \
        FocusTrain/Core/Map/MapStyle+Display.swift \
        FocusTrain/Resources/Localizable.xcstrings
git commit -m "feat(session): redesign active-ride chrome to flight-tracker layout"
```

(Drop `MapStyle+Display.swift` from the `add` if it didn't need to be created.)

---

## Task 11: Manual verification

This codebase has no XCTest target, so verification is by SwiftUI Preview + on-device/simulator smoke test.

**Files:** none.

- [ ] **Step 1: Run the app and start a short session**

Open `FocusTrain.xcodeproj` in Xcode, select iPhone 15 Pro simulator, run. From the home screen, start a 1-minute session.

- [ ] **Step 2: Verify each chrome element**

Confirm visually:

- Destination city name appears centered at the top as white bold text with a thick dark outline.
- End (X) button is in the top-right corner.
- Left pill on the left edge: top button is `pause.fill` dimmed (~40% opacity), inert to taps; bottom button is `music.note`. Tapping `pause.fill` does nothing. Tapping `music.note` opens the scenario menu.
- Right pill on the right edge: three buttons stacked. Top is Tunnel (`moon` → `moon.zzz.fill` and flips to white when tapped). Middle is Follow (`scope` ↔ `tram.fill`). Bottom is Map style (`map`) — tapping opens a menu.
- Bottom-left tile shows "TIME REMAINING" small uppercase + a large value like "1 min".
- Bottom-right tile shows "DISTANCE REMAINING" + a value like "12 km".
- Entrance animation: title slides down from above, pills slide in from their edges, tiles rise from below — all under one spring.
- Map and train continue to render and update behind chrome.
- End button opens the confirmation dialog; cancel keeps the session; confirm fires `onEnd`.

- [ ] **Step 3: Verify VoiceOver labels (optional but recommended)**

Enable VoiceOver. Swipe through the screen. Verify reading order: title → end → left pill (top→bottom) → right pill (top→bottom) → time tile → distance tile. Each tile reads "Time remaining, 1 minute" style. Each toggle reads its state.

- [ ] **Step 4: Final commit (if any cleanup)**

If verification revealed a small visual tweak (spacing, color, font size), make the edit and commit:

```bash
git add -p
git commit -m "fix(session): <specific tweak>"
```

Otherwise no commit needed.

---

## Done criteria for Phase 1

- All 11 tasks complete and committed.
- `xcodebuild ... build` succeeds with no warnings related to the new files.
- Manual smoke test passes for the items in Task 11 Step 2.
- The Pause button is visible and disabled — Phase 2 will activate it.
