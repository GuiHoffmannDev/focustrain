# Active Session Redesign — Phase 3 (Sound Modal) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Prereq:** Phase 2 is shipped — `SessionView` chrome uses iOS 26 `glassEffect`, the right side has Map and Rail (tunnel) buttons via the sheet pattern, Pause works.

**Goal:** Replace the vestigial inline `SessionMusicMenu` (which today opens a `FocusScenario` picker mis-labelled as "music") with a full-screen Sound modal. UI + persistence only — no real audio playback yet (Phase 4). Ship the surface so the chrome button means "sound" instead of "scenario", and Phase 4 can plug an `AVAudioPlayer` into the new `AmbientSoundController` without touching the views.

**Architecture:** New `AmbientSound` enum (separate from the existing `FocusScenario`, which stays untouched) and `AmbientSoundController` (Observable, mirrors `InAppTunnelController`). Six new SwiftUI views build the modal: `SoundSheet`, `AmbientSoundCard`, `ComingSoonCard`, `SoundMasterPill`, `MutePill`, `AirPlayButton`. `SessionView` swaps the old `SessionMusicMenu` for a `SessionControlButton` that opens the new sheet, deletes the now-dead `@State scenario`, and the `SessionMusicMenu.swift` file is removed entirely.

**Tech Stack:** SwiftUI (iOS 26 `glassEffect`), `Observation` (`@Observable`/`@Bindable`), `AVKit` (`AVRoutePickerView` wrapped via `UIViewRepresentable`), `UserDefaults` for persistence.

**Repo conventions reminder:**

- New `.swift` files appear automatically in the target via synced groups; `project.pbxproj` is never edited by hand.
- No XCTest target — verification is `xcodebuild build` + `#Preview` + manual smoke test in the simulator.
- No comments by default; only add one when the WHY is non-obvious.
- Each task = 1 commit. No `Co-Authored-By` trailer in commit messages.
- Working tree contains pre-existing modifications on other files (StarsBackground, GlobeHomeView, etc.) — never `git add -A`, always stage explicitly by path.

---

## File Structure

**Create:**

- `FocusTrain/Features/FocusSession/Models/AmbientSound.swift` — the `AmbientSound` and `AmbientSoundCategory` enums.
- `FocusTrain/Core/Sound/AmbientSoundController.swift` — `@Observable` controller. Mirrors the `Core/Tunnel/InAppTunnelController.swift` pattern (own dedicated directory inside `Core/`).
- `FocusTrain/Features/FocusSession/Views/Components/AirPlayButton.swift` — 40pt circular wrapper around `AVRoutePickerView`.
- `FocusTrain/Features/FocusSession/Views/Components/AmbientSoundCard.swift` — the 150×150 (aspect-1) card; also hosts `ComingSoonCard` as a sibling `struct` in the same file.
- `FocusTrain/Features/FocusSession/Views/Components/SoundMasterPill.swift` — compact pill in the sheet header.
- `FocusTrain/Features/FocusSession/Views/Components/MutePill.swift` — long pill next to the AirPlay button.
- `FocusTrain/Features/FocusSession/Views/Components/SoundSheet.swift` — the modal container that wires everything together.

**Modify:**

- `FocusTrain/Features/FocusSession/Views/SessionView.swift` — swap the music menu for a sheet-opening button, add the new state, add the `.sheet` modifier, delete dead `scenario` state.

**Delete:**

- `FocusTrain/Features/FocusSession/Views/Components/SessionMusicMenu.swift` — vestigial mis-labelled picker; no caller after Task 8.

**Untouched (called out so reviewers know):** `SessionControlButton`, `SessionControlPill`, `MapStyleSelector`, `InAppTunnelController`, `SessionViewModel`, `SessionStore`, `Ticket`, `FocusScenario`. `FocusScenario` is still used by Settings/Onboarding/History/ArrivalView/DurationPicker/TicketReveal — the visual scenario continues to be set pre-ride.

---

## Task 1: Add `AmbientSound` enum + category

**Files:**

- Create: `FocusTrain/Features/FocusSession/Models/AmbientSound.swift`

- [ ] **Step 1: Create the file**

Write `FocusTrain/Features/FocusSession/Models/AmbientSound.swift` with:

```swift
import SwiftUI

enum AmbientSoundCategory {
    case whiteNoise
    case focusSound
}

enum AmbientSound: String, CaseIterable, Identifiable {
    case airplane = "airplane"
    case raindrop = "raindrop"
    case ocean    = "ocean"
    case forest   = "forest"

    var id: String { rawValue }

    var displayKey: String { "sound.\(rawValue).title" }

    var symbol: String {
        switch self {
        case .airplane: return "airplane"
        case .raindrop: return "cloud.rain.fill"
        case .ocean:    return "water.waves"
        case .forest:   return "tree.fill"
        }
    }

    var gradient: [Color] {
        [FT.Palette.brandBrass, Color(hex: 0xB87A3C)]
    }

    var category: AmbientSoundCategory {
        switch self {
        case .airplane, .raindrop, .ocean, .forest: return .whiteNoise
        }
    }
}
```

Notes:

- `gradient` returns the same warm amber for every case in Phase 3 — kept as a per-case property so Phase 4 can vary palettes per sound without touching call sites.
- No comments beyond docstrings — none of the choices are non-obvious enough to warrant one per repo policy.

- [ ] **Step 2: Build**

```bash
xcodebuild -project FocusTrain.xcodeproj -scheme FocusTrain -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -20
```

Expected: `BUILD SUCCEEDED`. SourceKit may flash "Cannot find 'FT' in scope" briefly in the editor — only the build is authoritative.

- [ ] **Step 3: Commit**

```bash
git add FocusTrain/Features/FocusSession/Models/AmbientSound.swift
git commit -m "feat(sound): add AmbientSound + category enums"
```

---

## Task 2: Add `AmbientSoundController`

**Files:**

- Create: `FocusTrain/Core/Sound/AmbientSoundController.swift`

- [ ] **Step 1: Create the file**

Write `FocusTrain/Core/Sound/AmbientSoundController.swift` with:

```swift
import SwiftUI
import Observation

/// In-session source of truth for the ambient-sound UI. Persists the master
/// switch and the chosen sound across launches via UserDefaults. Mute is
/// session-ephemeral by design — a per-ride convenience, not a stored
/// preference. Phase 3 ships UI + persistence only; Phase 4 will hang an
/// AVAudioPlayer off `isPlaying` without touching the views.
@MainActor
@Observable
final class AmbientSoundController {
    private enum Keys {
        static let enabled   = "ambientSoundEnabled"
        static let selection = "ambientSoundSelection"
    }

    var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: Keys.enabled) }
    }

    var selected: AmbientSound? {
        didSet {
            UserDefaults.standard.set(selected?.rawValue ?? "", forKey: Keys.selection)
        }
    }

    var isMuted: Bool = false

    var isPlaying: Bool { isEnabled && !isMuted && selected != nil }

    init() {
        let defaults = UserDefaults.standard
        self.isEnabled = defaults.object(forKey: Keys.enabled) as? Bool ?? true
        let raw = defaults.string(forKey: Keys.selection) ?? ""
        self.selected = AmbientSound(rawValue: raw)
    }
}
```

Notes:

- `defaults.object(forKey:) as? Bool` returns `nil` on first launch → defaults to `true` per spec. Explicit `false` round-trips correctly.
- `selected` stores the raw string (empty for nil) and the init re-parses via `AmbientSound(rawValue: "")` which returns `nil` — clean round-trip.
- `init()` directly fires `didSet`? No — Swift suppresses `didSet` during init. Persistence only triggers on subsequent assignments. Good.

- [ ] **Step 2: Build**

```bash
xcodebuild -project FocusTrain.xcodeproj -scheme FocusTrain -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -20
```

Expected: `BUILD SUCCEEDED`.

- [ ] **Step 3: Commit**

```bash
git add FocusTrain/Core/Sound/AmbientSoundController.swift
git commit -m "feat(sound): add AmbientSoundController with UserDefaults persistence"
```

---

## Task 3: Add `AirPlayButton`

**Files:**

- Create: `FocusTrain/Features/FocusSession/Views/Components/AirPlayButton.swift`

- [ ] **Step 1: Create the file**

Write `FocusTrain/Features/FocusSession/Views/Components/AirPlayButton.swift` with:

```swift
import SwiftUI
import AVKit

/// 40pt circular button that opens the system AirPlay route picker. Wraps
/// AVRoutePickerView so it can sit inside SwiftUI alongside the other
/// 40pt glass controls.
struct AirPlayButton: View {
    var body: some View {
        RoutePicker()
            .frame(width: 40, height: 40)
            .background {
                Color.clear.glassEffect(.regular, in: Circle())
            }
            .accessibilityLabel(Text(NSLocalizedString("session.sound.airplay.a11y", comment: "")))
            .accessibilityAddTraits(.isButton)
    }

    private struct RoutePicker: UIViewRepresentable {
        func makeUIView(context: Context) -> AVRoutePickerView {
            let v = AVRoutePickerView()
            v.tintColor = UIColor.white
            v.activeTintColor = UIColor.white
            v.prioritizesVideoDevices = false
            v.backgroundColor = .clear
            return v
        }

        func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
    }
}

#Preview {
    AirPlayButton()
        .padding()
        .background(FT.Palette.bgElevated)
}
```

- [ ] **Step 2: Build**

```bash
xcodebuild -project FocusTrain.xcodeproj -scheme FocusTrain -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -20
```

Expected: `BUILD SUCCEEDED`. `AVRoutePickerView` is in `AVKit` — no extra capability needed.

- [ ] **Step 3: Commit**

```bash
git add FocusTrain/Features/FocusSession/Views/Components/AirPlayButton.swift
git commit -m "feat(sound): add AirPlayButton wrapper for AVRoutePickerView"
```

---

## Task 4: Add `AmbientSoundCard` + `ComingSoonCard`

**Files:**

- Create: `FocusTrain/Features/FocusSession/Views/Components/AmbientSoundCard.swift`

- [ ] **Step 1: Create the file**

Write `FocusTrain/Features/FocusSession/Views/Components/AmbientSoundCard.swift` with:

```swift
import SwiftUI

/// 1:1 card used in the SoundSheet's grid. Title top-leading, faint
/// background glyph filling the lower-right, ON/OFF label + dot
/// bottom-trailing. Pure presentation — the parent owns selection logic.
struct AmbientSoundCard: View {
    let sound: AmbientSound
    let isOn: Bool
    let isEnabled: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                background
                content
            }
            .aspectRatio(1, contentMode: .fit)
        }
        .buttonStyle(.plain)
        .opacity(isEnabled ? 1 : 0.5)
        .accessibilityLabel(Text(LocalizedStringKey(sound.displayKey)))
        .accessibilityValue(isOn ? "on" : "off")
        .accessibilityHint(Text(isOn ? "Double tap to turn off" : "Double tap to select"))
        .accessibilityAddTraits(.isButton)
    }

    @ViewBuilder
    private var background: some View {
        if isOn {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: sound.gradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay { glyph(opacity: 0.18) }
        } else {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.clear)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay { glyph(opacity: 0.12) }
        }
    }

    private func glyph(opacity: Double) -> some View {
        Image(systemName: sound.symbol)
            .font(.system(size: 90, weight: .semibold))
            .foregroundStyle(FT.Palette.white.opacity(opacity))
            .rotationEffect(.degrees(-12))
            .offset(x: 18, y: 18)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .allowsHitTesting(false)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(LocalizedStringKey(sound.displayKey))
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(FT.Palette.textPrimary)
                .lineLimit(2)
            Spacer(minLength: 0)
            HStack(spacing: 6) {
                Spacer()
                Circle()
                    .fill(isOn ? FT.Palette.white : FT.Palette.textMuted)
                    .frame(width: 6, height: 6)
                Text(NSLocalizedString(isOn ? "sound.state.on" : "sound.state.off", comment: ""))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(isOn ? FT.Palette.textPrimary : FT.Palette.textMuted)
            }
        }
        .padding(14)
    }
}

/// Placeholder card for the "Focus Sound" section. Non-interactive
/// disabled visual until Phase 4+ delivers the real focus tracks.
struct ComingSoonCard: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.clear)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay {
                    Image(systemName: "door.left.hand.closed")
                        .font(.system(size: 90, weight: .semibold))
                        .foregroundStyle(FT.Palette.white.opacity(0.10))
                        .rotationEffect(.degrees(-12))
                        .offset(x: 18, y: 18)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .allowsHitTesting(false)
                }
            VStack(alignment: .leading, spacing: 0) {
                Text(NSLocalizedString("sound.comingsoon.title", comment: ""))
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(FT.Palette.textPrimary)
                Spacer(minLength: 0)
                HStack(spacing: 6) {
                    Spacer()
                    Circle()
                        .fill(FT.Palette.textMuted)
                        .frame(width: 6, height: 6)
                    Text(NSLocalizedString("sound.state.off", comment: ""))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(FT.Palette.textMuted)
                }
            }
            .padding(14)
        }
        .aspectRatio(1, contentMode: .fit)
        .opacity(0.5)
        .allowsHitTesting(false)
        .accessibilityLabel(Text(NSLocalizedString("sound.comingsoon.title", comment: "")))
        .accessibilityAddTraits(.isStaticText)
    }
}

#Preview("Cards") {
    VStack(spacing: 16) {
        HStack(spacing: 12) {
            AmbientSoundCard(sound: .airplane, isOn: true, isEnabled: true, onTap: {})
            AmbientSoundCard(sound: .raindrop, isOn: false, isEnabled: true, onTap: {})
        }
        HStack(spacing: 12) {
            AmbientSoundCard(sound: .ocean, isOn: false, isEnabled: false, onTap: {})
            ComingSoonCard()
        }
    }
    .padding()
    .background(FT.Palette.bgElevated)
}
```

Notes:

- `NSLocalizedString("sound.airplane.title", ...)` returns the literal key string until the user adds the entry to `Localizable.xcstrings`. That's expected and does not break the build.
- The 90pt glyph + `offset(x: 18, y: 18)` + bottom-trailing alignment + clip creates the "fills the lower-right, peeking off the edge" look from the spec.

- [ ] **Step 2: Build**

```bash
xcodebuild -project FocusTrain.xcodeproj -scheme FocusTrain -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -20
```

Expected: `BUILD SUCCEEDED`.

- [ ] **Step 3: Commit**

```bash
git add FocusTrain/Features/FocusSession/Views/Components/AmbientSoundCard.swift
git commit -m "feat(sound): add AmbientSoundCard + ComingSoonCard"
```

---

## Task 5: Add `SoundMasterPill`

**Files:**

- Create: `FocusTrain/Features/FocusSession/Views/Components/SoundMasterPill.swift`

- [ ] **Step 1: Create the file**

Write `FocusTrain/Features/FocusSession/Views/Components/SoundMasterPill.swift` with:

```swift
import SwiftUI

/// Compact pill that sits in the SoundSheet's header row and toggles the
/// app's durable "Sound is allowed" preference. Active state is the
/// success-green from the palette; inactive falls back to glass.
struct SoundMasterPill: View {
    @Binding var isEnabled: Bool

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
                isEnabled.toggle()
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "music.note")
                    .font(.system(size: 12, weight: .bold))
                Text(NSLocalizedString(
                    isEnabled ? "session.sound.master.on" : "session.sound.master.off",
                    comment: ""
                ))
                .font(.system(size: 12, weight: .bold))
            }
            .foregroundStyle(isEnabled ? FT.Palette.white : FT.Palette.textSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background {
                if isEnabled {
                    Capsule().fill(FT.Palette.success)
                } else {
                    Capsule().fill(.clear).glassEffect(.regular, in: Capsule())
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("Sound"))
        .accessibilityValue(isEnabled ? "on" : "off")
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    HStack(spacing: 12) {
        SoundMasterPill(isEnabled: .constant(true))
        SoundMasterPill(isEnabled: .constant(false))
    }
    .padding()
    .background(FT.Palette.bgElevated)
}
```

- [ ] **Step 2: Build**

```bash
xcodebuild -project FocusTrain.xcodeproj -scheme FocusTrain -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -20
```

Expected: `BUILD SUCCEEDED`.

- [ ] **Step 3: Commit**

```bash
git add FocusTrain/Features/FocusSession/Views/Components/SoundMasterPill.swift
git commit -m "feat(sound): add SoundMasterPill"
```

---

## Task 6: Add `MutePill`

**Files:**

- Create: `FocusTrain/Features/FocusSession/Views/Components/MutePill.swift`

- [ ] **Step 1: Create the file**

Write `FocusTrain/Features/FocusSession/Views/Components/MutePill.swift` with:

```swift
import SwiftUI

/// Long glass pill that toggles the session-ephemeral mute. Sits next to
/// the AirPlay button in the SoundSheet's controls row, taking the
/// remaining horizontal width.
struct MutePill: View {
    @Binding var isMuted: Bool

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
                isMuted.toggle()
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.slash")
                    .font(.system(size: 14, weight: .bold))
                Text(NSLocalizedString(
                    isMuted ? "session.sound.muted" : "session.sound.mute",
                    comment: ""
                ))
                .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(FT.Palette.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background {
                Capsule().fill(.clear).glassEffect(.regular, in: Capsule())
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("Mute"))
        .accessibilityValue(isMuted ? "muted" : "unmuted")
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    VStack(spacing: 12) {
        MutePill(isMuted: .constant(false))
        MutePill(isMuted: .constant(true))
    }
    .padding()
    .background(FT.Palette.bgElevated)
}
```

- [ ] **Step 2: Build**

```bash
xcodebuild -project FocusTrain.xcodeproj -scheme FocusTrain -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -20
```

Expected: `BUILD SUCCEEDED`.

- [ ] **Step 3: Commit**

```bash
git add FocusTrain/Features/FocusSession/Views/Components/MutePill.swift
git commit -m "feat(sound): add MutePill"
```

---

## Task 7: Add `SoundSheet`

**Files:**

- Create: `FocusTrain/Features/FocusSession/Views/Components/SoundSheet.swift`

- [ ] **Step 1: Create the file**

Write `FocusTrain/Features/FocusSession/Views/Components/SoundSheet.swift` with:

```swift
import SwiftUI
import Observation

/// Modal that lets the traveller browse ambient sounds, toggle the master
/// switch, mute temporarily, and pick an AirPlay route. Phase 3 owns the
/// surface; Phase 4 will hang real audio off `sound.isPlaying`.
struct SoundSheet: View {
    @Bindable var sound: AmbientSoundController
    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    header
                    controlsRow
                    sectionHeader(key: "session.sound.section.white")
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(AmbientSound.allCases.filter { $0.category == .whiteNoise }) { ambient in
                            AmbientSoundCard(
                                sound: ambient,
                                isOn: sound.selected == ambient,
                                isEnabled: sound.isEnabled,
                                onTap: {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
                                        sound.selected = (sound.selected == ambient) ? nil : ambient
                                    }
                                }
                            )
                        }
                    }
                    sectionHeader(key: "session.sound.section.focus")
                    LazyVGrid(columns: columns, spacing: 12) {
                        ComingSoonCard()
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, FT.Layout.sideMargin)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    closeButton
                }
            }
        }
    }

    private var header: some View {
        HStack {
            Text(NSLocalizedString("session.sound.title", comment: ""))
                .font(FT.Typography.sectionTitle)
                .foregroundStyle(FT.Palette.textPrimary)
            Spacer()
            SoundMasterPill(isEnabled: $sound.isEnabled)
        }
    }

    private var controlsRow: some View {
        HStack(spacing: 12) {
            AirPlayButton()
            MutePill(isMuted: $sound.isMuted)
        }
    }

    private func sectionHeader(key: String) -> some View {
        HStack {
            Text(NSLocalizedString(key, comment: ""))
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(FT.Palette.textSecondary)
                .accessibilityAddTraits(.isHeader)
            Spacer()
        }
        .padding(.top, 4)
    }

    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(FT.Palette.textPrimary)
                .frame(width: 30, height: 30)
                .background(Circle().fill(FT.Palette.bgElevated.opacity(0.6)))
        }
        .accessibilityLabel(Text(NSLocalizedString("session.sound.close", comment: "")))
    }
}

#Preview {
    SoundSheet(sound: AmbientSoundController())
}
```

Notes:

- `@Bindable var sound` enables `$sound.isEnabled` and `$sound.isMuted` for the two pills. The card grid mutates `sound.selected` directly (no binding needed).
- Sheet presentation modifiers (`.presentationDetents`, etc.) live on the call site in `SessionView`, not here — keeps the preview clean and the sheet reusable.
- The close button is inlined verbatim from the map-style sheet pattern in [SessionView.swift:219-231](FocusTrain/Features/FocusSession/Views/SessionView.swift#L219-L231). Defer extraction until a 3rd callsite shows up.

- [ ] **Step 2: Build**

```bash
xcodebuild -project FocusTrain.xcodeproj -scheme FocusTrain -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -20
```

Expected: `BUILD SUCCEEDED`.

- [ ] **Step 3: Commit**

```bash
git add FocusTrain/Features/FocusSession/Views/Components/SoundSheet.swift
git commit -m "feat(sound): add SoundSheet modal"
```

---

## Task 8: Wire `SoundSheet` into `SessionView`, delete `SessionMusicMenu`

**Files:**

- Modify: `FocusTrain/Features/FocusSession/Views/SessionView.swift`
- Delete: `FocusTrain/Features/FocusSession/Views/Components/SessionMusicMenu.swift`

- [ ] **Step 1: Add new `@State` properties**

Find this block near the top of `SessionView` (around line 19–25):

```swift
    @State private var model: SessionViewModel
    @State private var tunnel = InAppTunnelController()
    @State private var cameraMode: CameraMode = .centerTrain
    @State private var appeared = false
    @State private var scenario: FocusScenario
    @State private var mapStyle: MapStyle
    @State private var showMapStyleSheet = false
```

Replace with:

```swift
    @State private var model: SessionViewModel
    @State private var tunnel = InAppTunnelController()
    @State private var sound = AmbientSoundController()
    @State private var cameraMode: CameraMode = .centerTrain
    @State private var appeared = false
    @State private var mapStyle: MapStyle
    @State private var showMapStyleSheet = false
    @State private var showSoundSheet = false
```

(`scenario` is removed. `sound` and `showSoundSheet` are added.)

- [ ] **Step 2: Remove the `_scenario` init line**

In the `init` (around line 30–37), find:

```swift
    init(ticket: Ticket, onArrive: @escaping () -> Void, onEnd: @escaping () -> Void) {
        self.ticket = ticket
        self.onArrive = onArrive
        self.onEnd = onEnd
        _model = State(initialValue: SessionViewModel(ticket: ticket))
        _scenario = State(initialValue: FocusScenario(rawValue: ticket.scenario) ?? .forest)
        _mapStyle = State(initialValue: MapStyle(rawValue: ticket.mapStyle) ?? .monochrome)
    }
```

Delete the `_scenario` line:

```swift
    init(ticket: Ticket, onArrive: @escaping () -> Void, onEnd: @escaping () -> Void) {
        self.ticket = ticket
        self.onArrive = onArrive
        self.onEnd = onEnd
        _model = State(initialValue: SessionViewModel(ticket: ticket))
        _mapStyle = State(initialValue: MapStyle(rawValue: ticket.mapStyle) ?? .monochrome)
    }
```

- [ ] **Step 3: Replace `SessionMusicMenu` with a sheet-opening button**

Find this block in the left `SessionControlPill` (around lines 104–107):

```swift
                    SessionMusicMenu(
                        scenario: $scenario,
                        onSelect: { session.updateScenario($0) }
                    )
```

Replace with:

```swift
                    SessionControlButton(
                        systemName: "music.note",
                        state: sound.selected != nil ? .active : .idle,
                        accessibilityLabel: NSLocalizedString("session.sound.a11y", comment: ""),
                        accessibilityValue: sound.selected?.rawValue ?? "off"
                    ) {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showSoundSheet = true
                    }
```

- [ ] **Step 4: Add the `.sheet` modifier**

Find the existing `.sheet(isPresented: $showMapStyleSheet)` block at the bottom of `body` (around lines 212–237). Immediately after its closing `}`, add a new sheet:

```swift
        .sheet(isPresented: $showSoundSheet) {
            SoundSheet(sound: sound)
                .presentationDetents([.large])
                .presentationBackground(.ultraThinMaterial)
                .presentationDragIndicator(.visible)
        }
```

The exact placement: the new `.sheet` modifier should be chained on the outer `ZStack` of `body`, immediately below the `.sheet(isPresented: $showMapStyleSheet) { ... }` block. SwiftUI allows multiple `.sheet(isPresented:)` modifiers stacked.

- [ ] **Step 5: Delete `SessionMusicMenu.swift`**

```bash
git rm FocusTrain/Features/FocusSession/Views/Components/SessionMusicMenu.swift
```

This file's only caller was removed in Step 3. `FocusScenario` itself stays — it's still used by other screens.

- [ ] **Step 6: Build**

```bash
xcodebuild -project FocusTrain.xcodeproj -scheme FocusTrain -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -30
```

Expected: `BUILD SUCCEEDED`. If the build complains about `SessionMusicMenu` being undefined anywhere else, run `grep -rn "SessionMusicMenu" FocusTrain` — there should be zero hits after the rm. If it complains about an unused `scenario` symbol, double-check Steps 1 and 2 actually landed.

- [ ] **Step 7: Commit**

```bash
git add FocusTrain/Features/FocusSession/Views/SessionView.swift
git commit -m "feat(session): wire SoundSheet, remove vestigial scenario menu"
```

The `git rm` from Step 5 already staged the deletion; it travels with this commit since the message captures both halves of the change.

---

## Task 9: Manual verification on simulator

**Files:** none.

- [ ] **Step 1: Build + run**

```bash
xcodebuild -project FocusTrain.xcodeproj -scheme FocusTrain -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -10
```

Then launch via Xcode (`Cmd+R`) targeting iPhone 17 Pro. Start a 2-minute ride from Home.

- [ ] **Step 2: Open the sheet**

Tap the music-note button in the left control pill.

- Expect: sheet slides up at `.large` detent over the live map. Title "Sound" on the left, green "♪ ON" pill on the right (default isEnabled = true on first launch). AirPlay circle + Mute pill below. "White Noise" section with 4 cards in a 2×2 grid, all showing "OFF" with a gray dot. "Focus Sound" section with a single dimmed "Coming Soon" card.

- [ ] **Step 3: Single selection**

Tap "Airplane".

- Expect: card swaps to the warm amber gradient, dot turns white, label flips to "ON". Other 3 cards stay OFF. Music-note chrome button (behind the sheet) is now in `.active` state — confirmable after dismissing the sheet.

Tap "Raindrop".

- Expect: Raindrop → ON, Airplane → OFF (single selection). Animation runs through `.spring(response: 0.4, dampingFraction: 0.82)`.

Tap "Raindrop" again.

- Expect: Raindrop → OFF, no card selected. Chrome button returns to `.idle`.

- [ ] **Step 4: Master toggle**

Tap "Forest" so a card is ON.

Tap the green "♪ ON" master pill.

- Expect: pill flips to glass + textSecondary glyph, label changes to "OFF". All 4 cards dim to ~50% opacity. The selected card retains its ON visual but dimmed — selection persists.

Tap a different card while master is OFF.

- Expect: selection still updates (different card lights up under the dim). This is by design — Phase 4's audio engine will check `isPlaying = isEnabled && !isMuted && selected != nil` before emitting sound.

Tap the master pill again.

- Expect: master back ON, cards back to full opacity, the still-selected card visible at full saturation.

- [ ] **Step 5: Mute pill**

Tap the Mute pill.

- Expect: glyph changes from `speaker.slash` to `speaker.slash.fill`, label "Mute" → "Muted". No other state changes — cards and master pill untouched. Animation runs through the same spring.

Tap again.

- Expect: returns to "Mute" / `speaker.slash`.

- [ ] **Step 6: AirPlay**

Tap the AirPlay circle.

- Expect: system route picker opens (a small popover listing audio output routes — likely just "iPhone" if no AirPlay devices on the network). Tap outside to dismiss it.

- [ ] **Step 7: Coming Soon is inert**

Tap the "Coming Soon" card.

- Expect: nothing happens. No haptic, no animation, no state change.

- [ ] **Step 8: Persistence — selection + master**

With Airplane selected and master ON, tap the X close button.

- Expect: sheet dismisses. Music-note chrome button shows `.active` state (Airplane is selected).

Reopen the sheet.

- Expect: Airplane card still shows ON, master pill still green.

Force-quit the simulator app (Cmd+Shift+H twice, swipe away). Relaunch.

- Expect: still on the ride. Reopen the sound sheet. Airplane card still ON, master pill still ON.

- [ ] **Step 9: Persistence — mute is ephemeral**

Inside the same session: mute the pill, then close the sheet, reopen it.

- Expect: mute pill state is preserved within the same session (controller instance lives on with the SessionView).

End the ride, start a brand-new ride, open the sound sheet.

- Expect: mute pill is back to "Mute" (unmuted) — controller is fresh. Selection and master pill state are restored from UserDefaults.

- [ ] **Step 10: Verify the music-note chrome reflects selection**

Outside the sheet, while no sound is selected, the music-note button should be `.idle` (glass + white glyph).

Open sheet → select Ocean → close.

- Expect: button is now `.active` (solid white background, ink-colored glyph).

- [ ] **Step 11: VoiceOver pass**

Enable VoiceOver (`Cmd+Option+Tab`× depending on simulator setup; or Settings → Accessibility). Focus the music-note button.

- Expect: reads "Sound settings, button, <selected raw value or 'off'>".

Open sheet, focus the master pill.

- Expect: "Sound, button, on/off".

Focus a card.

- Expect: "{sound name}, button, on/off. Double tap to select / Double tap to turn off."

Focus Coming Soon.

- Expect: "Coming Soon" — no button trait, no double-tap hint.

- [ ] **Step 12: No regression in existing chrome**

Pause works, Map style sheet still opens, Rail mode (tunnel) still toggles. Spot-check each existing button — Phase 3 must not have broken anything to its right or above.

- [ ] **Step 13: Final commit (only if cleanup needed)**

If anything required a fix during smoke testing, stage and commit it separately. Otherwise: skip.

```bash
git status
# If clean, nothing to do. Otherwise:
git add -p
git commit -m "fix(sound): <specific cleanup>"
```

---

## Strings to add manually in `Localizable.xcstrings`

The agent **does not** edit the xcstrings JSON (editing it by hand corrupts the catalog). After Task 8 builds green, open `FocusTrain/Resources/Localizable.xcstrings` in Xcode's String Catalog editor and add these keys. Until they exist, `NSLocalizedString` resolves to the key string — the app still works, the labels just look like dotted identifiers.

| Key | English | Portuguese |
|---|---|---|
| `session.sound.a11y` | Sound settings | Configurações de som |
| `session.sound.close` | Close | Fechar |
| `session.sound.title` | Sound | Som |
| `session.sound.master.on` | ON | LIGADO |
| `session.sound.master.off` | OFF | DESLIGADO |
| `session.sound.airplay.a11y` | AirPlay | AirPlay |
| `session.sound.mute` | Mute | Silenciar |
| `session.sound.muted` | Muted | Silenciado |
| `session.sound.section.white` | White Noise | Ruído Branco |
| `session.sound.section.focus` | Focus Sound | Som de Foco |
| `sound.airplane.title` | Airplane | Avião |
| `sound.raindrop.title` | Raindrop | Chuva |
| `sound.ocean.title` | Ocean Waves | Ondas do Mar |
| `sound.forest.title` | Forest | Floresta |
| `sound.comingsoon.title` | Coming Soon | Em Breve |
| `sound.state.on` | ON | LIGADO |
| `sound.state.off` | OFF | DESLIGADO |

The orphaned `session.music.a11y` key from Phase 1/2 can be removed in the same pass.

---

## Done criteria for Phase 3

- All 9 tasks complete and committed (8 implementation commits, Task 9 is verification only).
- `xcodebuild ... build` succeeds after every task.
- The 13 manual smoke checks in Task 9 all pass.
- `git grep SessionMusicMenu` returns zero hits.
- `git grep "@State private var scenario"` returns zero hits inside `SessionView.swift` (the property is gone). Other files using `FocusScenario` are untouched.
- Sound master state and selection persist across app force-quit; mute resets across new sessions.
- The pre-existing working-tree modifications listed in the project status (StarsBackground, GlobeHomeView, DurationPickerModel, DestinationMapView, DurationPickerView, HomeView, Localizable.xcstrings, DestinationCardStripView) are still uncommitted and untouched after Phase 3 — none of the 8 commits should have staged any of them.
