# "Escolha seu Destino" — Destination/Duration Picker Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the 4 duration chips in `ComposeJourneyView` with a synchronized radar + draggable time-ruler + destination carousel where choosing a destination IS choosing the focus duration.

**Architecture:** A single `@MainActor @Observable DurationPickerModel` is the source of truth (`selectedIndex` into a fixed 9-stop `Destination.ladder`). Three controls (`RadarDialView`, `TimeRulerView`, `DestinationCarouselView`) read it and write through one `select(_:from:)` mutator whose dedup + an `InteractionSource` guard prevent feedback loops. A new transient `DetentHapticsService` (modeled on the existing `TearHapticsService`) ticks per crossed mark. Flow order is preserved: the screen swaps into `RootView.Route.compose` and still calls `onDepart(ticket)` → `SeatPicker`.

**Tech Stack:** SwiftUI (iOS 17+/macOS 14+), Observation, Core Haptics, CoreLocation. Single Xcode target `FocusTrain`. Spec: `docs/superpowers/specs/2026-06-01-destination-duration-picker-design.md`.

---

## Project conventions (read once, apply to every task)

- **NEVER edit `FocusTrain.xcodeproj/project.pbxproj`.** New `.swift` files dropped into `FocusTrain/...` folders are auto-added to the target (PBXFileSystemSynchronizedRootGroup). SourceKit may show stale "Cannot find X in scope" warnings on brand-new files until the next build — ignore them, trust `xcodebuild`.
- **Accent is WHITE** (`FT.Palette.brandRail = #FFFFFF`). Brass (`#E0A458`) is secondary warmth. No yellow.
- **All user-facing copy** goes through `NSLocalizedString(...)`; keys are added to `FocusTrain/Resources/Localizable.xcstrings`.
- **No XCTest target exists**, and adding one needs forbidden `.pbxproj` edits. Verification is therefore: (a) `xcodebuild` build succeeds, and (b) a `#Preview` self-check (pure logic) or a simulator interaction check (UI). This is the project's established method.
- Match the visual cadence of `ComposeJourneyView`/`SeatPickerView`: `FT.Palette.black` background, `RadialGradient(brandRail.opacity(0.10))` backdrop glow from `.top`, spring reveal on appear, back-chevron toolbar, `CTAButton(style: .primary)` fixed at the bottom over a black gradient.

### Verification commands (referenced by tasks as **VERIFY-BUILD** / **VERIFY-RUN**)

**VERIFY-BUILD:**
```bash
cd /Users/guilhermehoffmann/Desktop/Projects/FocusTrain
xcodebuild -project FocusTrain.xcodeproj -scheme FocusTrain \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -8
```
Expected: ends with `** BUILD SUCCEEDED **`.

**VERIFY-RUN** (install + launch in the simulator to observe behavior):
```bash
cd /Users/guilhermehoffmann/Desktop/Projects/FocusTrain
xcrun simctl boot "iPhone 17 Pro" 2>/dev/null; open -a Simulator
APP=$(xcodebuild -project FocusTrain.xcodeproj -scheme FocusTrain \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -showBuildSettings 2>/dev/null | awk -F' = ' '/ CODESIGNING_FOLDER_PATH/{print $2; exit}')
xcrun simctl install "iPhone 17 Pro" "$APP"
xcrun simctl launch "iPhone 17 Pro" testapp.FocusTrain
```
If the onboarding gate (`hasCompletedOnboarding`) blocks Home, complete onboarding once in the sim (it persists). Then tap **Start** to reach this screen.

---

## File structure

**Create:**
- `FocusTrain/Features/FocusSession/Models/Destination.swift` — `Destination` struct + fixed `ladder`.
- `FocusTrain/Features/BoardingPass/Services/DetentHapticsService.swift` — transient tick service + fallbacks.
- `FocusTrain/Features/FocusSession/ViewModels/DurationPickerModel.swift` — source of truth.
- `FocusTrain/Features/FocusSession/Views/Components/TimeRulerView.swift`
- `FocusTrain/Features/FocusSession/Views/Components/RadarDialView.swift`
- `FocusTrain/Features/FocusSession/Views/Components/DestinationPin.swift`
- `FocusTrain/Features/FocusSession/Views/Components/DestinationCarouselView.swift`
- `FocusTrain/Features/FocusSession/Views/Components/DestinationCard.swift`
- `FocusTrain/Features/FocusSession/Views/DurationPickerView.swift` — container.

**Modify:**
- `FocusTrain/ContentView.swift` — `RootView.destination(for:)` swaps `ComposeJourneyView` → `DurationPickerView`.
- `FocusTrain/Resources/Localizable.xcstrings` — add `durationPicker.*` keys.

**Delete (retire):**
- `FocusTrain/Features/FocusSession/Views/ComposeJourneyView.swift`
- `FocusTrain/Features/FocusSession/ViewModels/ComposeJourneyViewModel.swift`

---

## Task 0: Initialize git + baseline build

Frequent commits are the checkpoints the execution skills rely on; this repo has no git yet.

**Files:** none (repo setup).

- [ ] **Step 1: Init repo + ignore build cruft**

```bash
cd /Users/guilhermehoffmann/Desktop/Projects/FocusTrain
git init
printf '%s\n' 'xcuserdata/' '*.xcuserstate' 'DerivedData/' '.DS_Store' > .gitignore
git add -A
git commit -m "chore: baseline before destination/duration picker"
```

- [ ] **Step 2: Baseline build is green**

Run **VERIFY-BUILD**. Expected: `** BUILD SUCCEEDED **`. If it fails before any change, stop and report — the baseline is broken.

---

## Task 1: `Destination` model + fixed ladder

**Files:**
- Create: `FocusTrain/Features/FocusSession/Models/Destination.swift`

- [ ] **Step 1: Write the model + ladder + a self-check `#Preview`**

The `#Preview` is the "test": it computes invariants (9 stops, every code resolves in `StationPool`, minutes strictly increasing, `nominalKm` strictly increasing) and renders PASS/FAIL. Write it first so the build is red until the type exists.

```swift
import SwiftUI

/// One stop on the duration ladder. Picking a destination sets both the route's
/// destination and the focus duration. `nominalKm` is a *stylized* distance that
/// grows with `minutes` (shown on cards/radar) — not a real great-circle value.
struct Destination: Identifiable, Hashable {
    let station: Station
    let minutes: Int
    let nominalKm: Int
    /// Curated angle on the radar ring (degrees, 0 = right, clockwise). Not a geographic bearing.
    let radarDegrees: Double

    var id: String { station.code }
    var code: String { station.code }
    var city: String { station.city }
}

extension Destination {
    /// Fixed 9-stop ladder (15–90 min). All codes exist in `StationPool`.
    static let ladder: [Destination] = {
        let rows: [(code: String, minutes: Int, km: Int)] = [
            ("LIS", 15,  250), ("MAD", 20,  400), ("PAR", 25,  600),
            ("ROM", 30,  850), ("IST", 40, 1300), ("DXB", 50, 2000),
            ("DEL", 60, 3000), ("BKK", 75, 4500), ("TYO", 90, 6500),
        ]
        let n = rows.count
        let start = 130.0, sweep = 280.0   // spread across a 280° arc, gap at bottom
        return rows.enumerated().map { idx, r in
            guard let station = StationPool.station(forCode: r.code) else {
                fatalError("Destination ladder references unknown station code \(r.code)")
            }
            let deg = start + sweep * Double(idx) / Double(n - 1)
            return Destination(station: station, minutes: r.minutes, nominalKm: r.km, radarDegrees: deg)
        }
    }()
}

#if DEBUG
#Preview("Destination ladder self-check") {
    let l = Destination.ladder
    let countOK   = l.count == 9
    let codesOK   = l.allSatisfy { StationPool.station(forCode: $0.code) != nil }
    let minutesOK = zip(l, l.dropFirst()).allSatisfy { $0.minutes < $1.minutes }
    let kmOK      = zip(l, l.dropFirst()).allSatisfy { $0.nominalKm < $1.nominalKm }
    let pass = countOK && codesOK && minutesOK && kmOK
    return VStack(alignment: .leading, spacing: 6) {
        Text(pass ? "PASS ✓" : "FAIL ✗").font(.title.bold())
            .foregroundStyle(pass ? .green : .red)
        Text("count=\(l.count) codes=\(codesOK) minutesAsc=\(minutesOK) kmAsc=\(kmOK)")
            .font(.caption.monospaced())
        ForEach(l) { d in Text("\(d.minutes)m · \(d.code) \(d.city) · ~\(d.nominalKm)km · \(Int(d.radarDegrees))°").font(.caption2.monospaced()) }
    }.padding()
}
#endif
```

- [ ] **Step 2: VERIFY-BUILD** → `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Confirm the self-check** — open `Destination.swift` in Xcode and run the "Destination ladder self-check" preview (Canvas ▶). Expected: large green **PASS ✓**, 9 rows listed. (Or trust the invariants if running headless — they hold for the data above.)

- [ ] **Step 4: Commit**

```bash
git add FocusTrain/Features/FocusSession/Models/Destination.swift
git commit -m "feat: Destination model + fixed 9-stop ladder"
```

---

## Task 2: `DetentHapticsService` (transient tick)

Mirrors `TearHapticsService`'s structure (capability detection, `isiOSAppOnMac` guard, impact fallback, macOS no-op) but plays a single **transient** event — the right primitive for a ruler detent.

**Files:**
- Create: `FocusTrain/Features/BoardingPass/Services/DetentHapticsService.swift`

- [ ] **Step 1: Write the service**

```swift
import Foundation
#if os(iOS)
import UIKit
import CoreHaptics
#endif

/// A single crisp "tick" per detent crossed (ruler mark / selection change).
protocol DetentHapticsService: AnyObject {
    func prepare()
    func tick()
}

enum DetentHaptics {
    static func make() -> DetentHapticsService {
        #if os(iOS)
        if !ProcessInfo.processInfo.isiOSAppOnMac,
           CHHapticEngine.capabilitiesForHardware().supportsHaptics {
            return CoreHapticsDetentService()
        }
        return ImpactDetentService()
        #else
        return NoopDetentService()
        #endif
    }
}

final class NoopDetentService: DetentHapticsService {
    func prepare() {}
    func tick() {}
}

#if os(iOS)
/// Crisp transient tick via Core Haptics.
final class CoreHapticsDetentService: DetentHapticsService {
    private var engine: CHHapticEngine?

    func prepare() {
        guard engine == nil else { return }
        do {
            let e = try CHHapticEngine()
            e.isAutoShutdownEnabled = true
            e.stoppedHandler = { [weak self] _ in self?.engine = nil }
            e.resetHandler = { [weak self] in try? self?.engine?.start() }
            try e.start()
            engine = e
        } catch { engine = nil }
    }

    func tick() {
        guard let engine else { return }
        do {
            let event = CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
            ], relativeTime: 0)
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {}
    }
}

/// Fallback for devices without Core Haptics.
final class ImpactDetentService: DetentHapticsService {
    private let gen = UIImpactFeedbackGenerator(style: .rigid)
    func prepare() { gen.prepare() }
    func tick() { gen.impactOccurred(intensity: 0.85); gen.prepare() }
}
#endif
```

- [ ] **Step 2: VERIFY-BUILD** → `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Commit**

```bash
git add FocusTrain/Features/BoardingPass/Services/DetentHapticsService.swift
git commit -m "feat: DetentHapticsService (transient tick + fallbacks)"
```

---

## Task 3: `DurationPickerModel` (source of truth)

**Files:**
- Create: `FocusTrain/Features/FocusSession/ViewModels/DurationPickerModel.swift`

- [ ] **Step 1: Write the model + a self-check `#Preview`**

Mirrors `ComposeJourneyViewModel`'s `UserDefaults` seeding and `makeTicket()` shape exactly (so nothing downstream changes). `select(_:from:)` is the single mutator: clamp, dedup, tick-on-real-change. The dedup is what stops the carousel's programmatic-scroll echo; `interactionSource` lets a view know who's driving.

```swift
import SwiftUI
import Observation
import CoreLocation

/// Single source of truth for the destination/duration picker. `selectedIndex`
/// into `destinations` is the only stored selection; everything visual derives
/// from it. Seeds scenario/mapStyle from onboarding defaults like the old
/// ComposeJourneyViewModel, and builds the active-session Ticket.
@MainActor
@Observable
final class DurationPickerModel {
    enum InteractionSource: Equatable { case none, ruler, radar, carousel }

    let destinations: [Destination]
    private(set) var origin: Station
    private(set) var selectedIndex: Int
    var interactionSource: InteractionSource = .none

    var scenario: FocusScenario
    var mapStyle: MapStyle

    private let haptics: DetentHapticsService

    var selectedDestination: Destination { destinations[selectedIndex] }

    init(destinations: [Destination] = Destination.ladder,
         origin: Station? = nil,
         haptics: DetentHapticsService = DetentHaptics.make()) {
        self.destinations = destinations
        self.haptics = haptics
        self.origin = origin ?? StationPool.all.randomElement()!

        // Default to 25 min (classic) if present, else the middle stop.
        self.selectedIndex = destinations.firstIndex(where: { $0.minutes == 25 })
            ?? (destinations.count / 2)

        let defaults = UserDefaults.standard
        if let raw = defaults.string(forKey: "defaultScenario"), let s = FocusScenario(rawValue: raw) {
            scenario = s
        } else {
            scenario = .forest
        }
        if let raw = defaults.string(forKey: "defaultMapStyle"), let m = MapStyle(rawValue: raw) {
            mapStyle = m
        } else {
            mapStyle = .monochrome
        }
    }

    func prepareHaptics() { haptics.prepare() }

    func beginInteraction(_ source: InteractionSource) { interactionSource = source }
    func endInteraction() { interactionSource = .none }

    /// The one mutator. Clamps to range, ignores no-op changes (breaks echo
    /// loops), and ticks only when the index actually moves.
    func select(_ index: Int, from source: InteractionSource) {
        let clamped = min(max(index, 0), destinations.count - 1)
        guard clamped != selectedIndex else { return }
        selectedIndex = clamped
        haptics.tick()
    }

    /// Origin = the user's current city when available (set by the view from
    /// CurrentCityResolver); otherwise the random fallback chosen in init.
    func setOrigin(city: String, coordinate: CLLocationCoordinate2D) {
        origin = Self.originStation(city: city, coordinate: coordinate)
    }

    static func originStation(city: String, coordinate: CLLocationCoordinate2D) -> Station {
        let upper = city.uppercased().unicodeScalars.filter { CharacterSet.uppercaseLetters.contains($0) }
        let code = String(String(String.UnicodeScalarView(upper)).prefix(3))
        return Station(code: code.isEmpty ? "ORG" : code,
                       city: city,
                       lat: coordinate.latitude,
                       lon: coordinate.longitude)
    }

    func makeTicket(departingAt departDate: Date = .now) -> Ticket {
        let dest = selectedDestination
        return Ticket(
            scenario: scenario.rawValue,
            fromCode: origin.code, fromCity: origin.city,
            toCode: dest.station.code, toCity: dest.station.city,
            fromLat: origin.lat, fromLon: origin.lon,
            toLat: dest.station.lat, toLon: dest.station.lon,
            departDate: departDate,
            durationMinutes: dest.minutes,
            mapStyle: mapStyle.rawValue,
            code: Ticket.makeCode()
        )
    }
}

#if DEBUG
#Preview("DurationPickerModel self-check") {
    let m = DurationPickerModel(haptics: NoopDetentService())
    // clamp
    m.select(999, from: .ruler); let clampHi = m.selectedIndex == m.destinations.count - 1
    m.select(-5, from: .ruler);  let clampLo = m.selectedIndex == 0
    // dedup: selecting the same index twice keeps it put
    m.select(3, from: .radar); let after = m.selectedIndex; m.select(3, from: .carousel)
    let dedup = m.selectedIndex == after && after == 3
    // ticket reflects selection
    m.select(m.destinations.firstIndex { $0.minutes == 90 }!, from: .ruler)
    let t = m.makeTicket()
    let ticketOK = t.durationMinutes == 90 && t.toCode == "TYO" && t.fromCode == m.origin.code
    let pass = clampHi && clampLo && dedup && ticketOK
    return VStack(alignment: .leading, spacing: 6) {
        Text(pass ? "PASS ✓" : "FAIL ✗").font(.title.bold()).foregroundStyle(pass ? .green : .red)
        Text("clampHi=\(clampHi) clampLo=\(clampLo) dedup=\(dedup) ticket=\(ticketOK)").font(.caption.monospaced())
        Text("ticket: \(t.fromCode)→\(t.toCode) \(t.durationMinutes)m").font(.caption2.monospaced())
    }.padding()
}
#endif
```

- [ ] **Step 2: VERIFY-BUILD** → `** BUILD SUCCEEDED **`. (`FocusScenario` is a `String` enum with `.forest` in `Features/FocusSession/Models/FocusScenario.swift`; `MapStyle` is a `String` enum with `.monochrome` in `Core/DesignSystem/Components/MapStyleSelector.swift` — both confirmed. The `Ticket(...)` call mirrors `ComposeJourneyViewModel.makeTicket()` field-for-field, so it compiles identically.)

- [ ] **Step 3: Confirm the self-check** — run the "DurationPickerModel self-check" preview. Expected: green **PASS ✓**.

- [ ] **Step 4: Commit**

```bash
git add FocusTrain/Features/FocusSession/ViewModels/DurationPickerModel.swift
git commit -m "feat: DurationPickerModel source of truth (select/dedup/makeTicket)"
```

---

## Task 4: `TimeRulerView` (primary control)

Horizontal odometer drawn in a single `Canvas`; a fixed center down-triangle indicator; the scale moves under it. Drag scrubs continuously, ticks per crossed mark, snaps on release. Idle offset derives from `selectedIndex` so radar/card taps animate the ruler. Carries the `.adjustable` VoiceOver trait.

**Files:**
- Create: `FocusTrain/Features/FocusSession/Views/Components/TimeRulerView.swift`

- [ ] **Step 1: Write the view**

```swift
import SwiftUI

struct TimeRulerView: View {
    let model: DurationPickerModel

    private let spacing: CGFloat = 66

    @State private var dragStartScrollX: CGFloat? = nil   // non-nil while dragging
    @State private var liveScrollX: CGFloat = 0

    private var maxScrollX: CGFloat { CGFloat(model.destinations.count - 1) * spacing }
    private var a11yValue: String {
        let d = model.selectedDestination
        return "\(d.city), \(d.minutes) " + NSLocalizedString("durationPicker.minutes", comment: "")
    }

    var body: some View {
        GeometryReader { geo in
            let centerX = geo.size.width / 2
            let dragging = dragStartScrollX != nil
            let scrollX = dragging ? liveScrollX : CGFloat(model.selectedIndex) * spacing

            Canvas { ctx, size in
                let midY = size.height / 2
                for (i, dest) in model.destinations.enumerated() {
                    let x = centerX - scrollX + CGFloat(i) * spacing
                    guard x > -60, x < size.width + 60 else { continue }
                    let sel = i == model.selectedIndex
                    var tick = Path()
                    tick.move(to: CGPoint(x: x, y: midY - (sel ? 18 : 11)))
                    tick.addLine(to: CGPoint(x: x, y: midY + (sel ? 18 : 11)))
                    ctx.stroke(tick,
                               with: .color(.white.opacity(sel ? 1.0 : 0.35)),
                               lineWidth: sel ? 2.5 : 1.5)
                    let label = Text("\(dest.minutes)")
                        .font(.system(size: sel ? 16 : 12, weight: sel ? .bold : .medium))
                        .foregroundColor(.white.opacity(sel ? 1.0 : 0.5))
                    ctx.draw(label, at: CGPoint(x: x, y: midY + 34))
                }
            }
            .overlay(alignment: .top) {
                Image(systemName: "arrowtriangle.down.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(FT.Palette.brandRail)
                    .position(x: centerX, y: 6)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { value in
                        if dragStartScrollX == nil {
                            dragStartScrollX = CGFloat(model.selectedIndex) * spacing
                            model.beginInteraction(.ruler)
                        }
                        let proposed = (dragStartScrollX ?? 0) - value.translation.width
                        liveScrollX = min(max(proposed, -spacing * 0.4), maxScrollX + spacing * 0.4)
                        model.select(Int((liveScrollX / spacing).rounded()), from: .ruler)
                    }
                    .onEnded { _ in
                        dragStartScrollX = nil
                        model.endInteraction()
                    }
            )
            .animation(dragging ? nil : .spring(response: 0.4, dampingFraction: 0.85),
                       value: model.selectedIndex)
        }
        .frame(height: 78)
        .accessibilityElement()
        .accessibilityLabel(Text(NSLocalizedString("durationPicker.ruler.a11yLabel", comment: "")))
        .accessibilityValue(Text(a11yValue))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: model.select(model.selectedIndex + 1, from: .ruler)
            case .decrement: model.select(model.selectedIndex - 1, from: .ruler)
            @unknown default: break
            }
        }
    }
}

#if DEBUG
#Preview("TimeRuler") {
    let m = DurationPickerModel(haptics: NoopDetentService())
    return ZStack {
        FT.Palette.black.ignoresSafeArea()
        VStack(spacing: 24) {
            Text("\(m.selectedDestination.minutes)m").font(.system(size: 40, weight: .heavy))
                .foregroundStyle(.white)
            TimeRulerView(model: m)
        }
    }
}
#endif
```

- [ ] **Step 2: VERIFY-BUILD** → `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Observe in the preview/sim** — run the "TimeRuler" preview. Expected: a row of minute labels (15…90), the centered one bold/tall under the white triangle; dragging left/right moves the scale under the triangle and the bold selection + the big readout change as marks pass center; releasing leaves a mark centered (snapped). On a physical device a tick is felt per mark (no haptics in the simulator — expected).

- [ ] **Step 4: Commit**

```bash
git add FocusTrain/Features/FocusSession/Views/Components/TimeRulerView.swift
git commit -m "feat: TimeRulerView (Canvas odometer, drag-snap, detent, a11y adjustable)"
```

---

## Task 5: `RadarDialView` + `DestinationPin`

Origin dot at center; a needle that springs to the selected pin; pins placed at `radarDegrees` on the ring; tap a pin to select.

**Files:**
- Create: `FocusTrain/Features/FocusSession/Views/Components/DestinationPin.swift`
- Create: `FocusTrain/Features/FocusSession/Views/Components/RadarDialView.swift`

- [ ] **Step 1: Write `DestinationPin`**

```swift
import SwiftUI

struct DestinationPin: View {
    let destination: Destination
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: "airplane")
                .font(.system(size: 9, weight: .bold))
                .rotationEffect(.degrees(-45))
            Text(destination.code)
                .font(.system(size: 10, weight: .heavy))
        }
        .foregroundStyle(isSelected ? FT.Palette.ink : FT.Palette.white)
        .padding(.horizontal, 7).padding(.vertical, 5)
        .background(
            Capsule().fill(isSelected ? FT.Palette.brandRail : FT.Palette.bgElevated.opacity(0.7))
        )
        .overlay(
            Capsule().stroke(isSelected ? Color.clear : FT.Palette.textMuted.opacity(0.35), lineWidth: 1)
        )
        .scaleEffect(isSelected ? 1.12 : 1.0)
        .accessibilityElement()
        .accessibilityLabel(Text("\(destination.city), \(destination.minutes) " + NSLocalizedString("durationPicker.minutes", comment: "")))
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }
}
```

- [ ] **Step 2: Write `RadarDialView`**

```swift
import SwiftUI

struct RadarDialView: View {
    let model: DurationPickerModel

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let ringR = side / 2 - 26
            let sel = model.selectedDestination

            ZStack {
                // Concentric rings
                ForEach(1...3, id: \.self) { i in
                    Circle()
                        .stroke(FT.Palette.textMuted.opacity(0.18), lineWidth: 1)
                        .frame(width: ringR * 2 * CGFloat(i) / 3, height: ringR * 2 * CGFloat(i) / 3)
                        .position(center)
                }

                // Needle to the selected pin
                Path { p in
                    p.move(to: center)
                    p.addLine(to: point(for: sel.radarDegrees, radius: ringR, center: center))
                }
                .stroke(FT.Palette.brandRail, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .animation(.spring(response: 0.45, dampingFraction: 0.8), value: model.selectedIndex)

                // Origin dot
                Circle().fill(FT.Palette.brandRail)
                    .frame(width: 10, height: 10).position(center)

                // Pins
                ForEach(Array(model.destinations.enumerated()), id: \.element.id) { idx, dest in
                    DestinationPin(destination: dest, isSelected: idx == model.selectedIndex)
                        .position(point(for: dest.radarDegrees, radius: ringR, center: center))
                        .onTapGesture {
                            model.beginInteraction(.radar)
                            model.select(idx, from: .radar)
                            model.endInteraction()
                        }
                }
            }
        }
        .frame(height: 280)
    }

    private func point(for degrees: Double, radius: CGFloat, center: CGPoint) -> CGPoint {
        let r = degrees * .pi / 180
        return CGPoint(x: center.x + radius * cos(r), y: center.y + radius * sin(r))
    }
}

#if DEBUG
#Preview("Radar") {
    let m = DurationPickerModel(haptics: NoopDetentService())
    return ZStack { FT.Palette.black.ignoresSafeArea(); RadarDialView(model: m).padding() }
}
#endif
```

- [ ] **Step 3: VERIFY-BUILD** → `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Observe** — run the "Radar" preview. Expected: a center dot, 9 code pins spread around an arc, the needle pointing at the selected pin (solid white); tapping another pin springs the needle to it and swaps the highlight.

- [ ] **Step 5: Commit**

```bash
git add FocusTrain/Features/FocusSession/Views/Components/DestinationPin.swift \
        FocusTrain/Features/FocusSession/Views/Components/RadarDialView.swift
git commit -m "feat: RadarDialView + DestinationPin (animated needle, tap-to-select)"
```

---

## Task 6: `DestinationCarouselView` + `DestinationCard`

Horizontal cards; selected highlighted; tap to select; auto-centers the selected card when another control drives the selection — guarded so the programmatic scroll never echoes back.

**Files:**
- Create: `FocusTrain/Features/FocusSession/Views/Components/DestinationCard.swift`
- Create: `FocusTrain/Features/FocusSession/Views/Components/DestinationCarouselView.swift`

- [ ] **Step 1: Write `DestinationCard`**

```swift
import SwiftUI

struct DestinationCard: View {
    let destination: Destination
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(destination.code)
                .font(.system(size: 20, weight: .heavy))
            Text(destination.city)
                .font(.system(size: 13, weight: .medium))
                .lineLimit(1).minimumScaleFactor(0.7)
            HStack(spacing: 6) {
                Text("\(destination.minutes)m").font(.system(size: 15, weight: .bold))
                Text("·").opacity(0.5)
                Text("~\(destination.nominalKm)km").font(.system(size: 12, weight: .medium)).opacity(0.7)
            }
        }
        .foregroundStyle(isSelected ? FT.Palette.ink : FT.Palette.white)
        .frame(width: 140, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(isSelected ? FT.Palette.brandRail : FT.Palette.bgElevated.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(isSelected ? Color.clear : FT.Palette.textMuted.opacity(0.25), lineWidth: 1)
        )
        .scaleEffect(isSelected ? 1.03 : 1.0)
    }
}
```

- [ ] **Step 2: Write `DestinationCarouselView`**

`isSyncing` swallows the `onChange(of: scrolledID)` that our own programmatic centering triggers; the `interactionSource != .carousel` guard stops re-centering while the carousel itself is the driver. Combined with `select()`'s dedup, no loops.

```swift
import SwiftUI

struct DestinationCarouselView: View {
    let model: DurationPickerModel

    @State private var scrolledID: String?
    @State private var isSyncing = false

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 12) {
                ForEach(Array(model.destinations.enumerated()), id: \.element.id) { idx, dest in
                    DestinationCard(destination: dest, isSelected: idx == model.selectedIndex)
                        .id(dest.id)
                        .onTapGesture {
                            model.beginInteraction(.carousel)
                            model.select(idx, from: .carousel)
                            model.endInteraction()
                        }
                }
            }
            .scrollTargetLayout()
            .padding(.horizontal, FT.Layout.sideMargin)
        }
        .scrollPosition(id: $scrolledID, anchor: .center)
        .scrollTargetBehavior(.viewAligned)
        .frame(height: 110)
        .onAppear {
            isSyncing = true
            scrolledID = model.selectedDestination.id
        }
        .onChange(of: model.selectedIndex) { _, _ in
            guard model.interactionSource != .carousel else { return }
            isSyncing = true
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                scrolledID = model.selectedDestination.id
            }
        }
        .onChange(of: scrolledID) { _, newID in
            if isSyncing { isSyncing = false; return }   // ignore our own programmatic scroll
            guard let newID, let idx = model.destinations.firstIndex(where: { $0.id == newID }) else { return }
            model.select(idx, from: .carousel)
        }
    }
}

#if DEBUG
#Preview("Carousel") {
    let m = DurationPickerModel(haptics: NoopDetentService())
    return ZStack { FT.Palette.black.ignoresSafeArea(); DestinationCarouselView(model: m) }
}
#endif
```

- [ ] **Step 3: VERIFY-BUILD** → `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Observe** — run the "Carousel" preview. Expected: cards scroll horizontally; the centered card is highlighted (white fill, dark text); tapping a card selects + recenters it; no flicker/fighting.

- [ ] **Step 5: Commit**

```bash
git add FocusTrain/Features/FocusSession/Views/Components/DestinationCard.swift \
        FocusTrain/Features/FocusSession/Views/Components/DestinationCarouselView.swift
git commit -m "feat: DestinationCarouselView + DestinationCard (guarded scroll sync)"
```

---

## Task 7: `DurationPickerView` container + wire into `RootView`

Composes the three controls + the big time readout + `ScenarioChips` + the `Depart` CTA. Resolves origin from `CurrentCityResolver` like `HomeView`. Swaps into `RootView.Route.compose`. This is where the three-way sync is exercised together for the first time.

**Files:**
- Create: `FocusTrain/Features/FocusSession/Views/DurationPickerView.swift`
- Modify: `FocusTrain/ContentView.swift` (the `.compose` case of `RootView.destination(for:)`)

- [ ] **Step 1: Write `DurationPickerView`**

```swift
import SwiftUI

struct DurationPickerView: View {
    /// Called with the freshly-built ticket when the user departs.
    var onDepart: (Ticket) -> Void
    var onBack: () -> Void

    @State private var model = DurationPickerModel()
    @State private var resolver = CurrentCityResolver()
    @State private var appeared = false

    var body: some View {
        ZStack {
            FT.Palette.black.ignoresSafeArea()
            RadialGradient(colors: [FT.Palette.brandRail.opacity(0.10), .clear],
                           center: .top, startRadius: 0, endRadius: 420)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    Text(NSLocalizedString("durationPicker.title", comment: ""))
                        .font(FT.Typography.sectionTitle)
                        .foregroundStyle(FT.Palette.white)
                        .opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 12)

                    RadarDialView(model: model)
                        .opacity(appeared ? 1 : 0).scaleEffect(appeared ? 1 : 0.96)

                    VStack(spacing: 10) {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(model.selectedDestination.minutes)")
                                .font(.system(size: 44, weight: .heavy))
                                .contentTransition(.numericText())
                            Text(NSLocalizedString("durationPicker.minutes", comment: ""))
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(FT.Palette.textSecondary)
                        }
                        .foregroundStyle(FT.Palette.white)
                        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: model.selectedIndex)

                        TimeRulerView(model: model)
                    }
                    .opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 16)

                    DestinationCarouselView(model: model)
                        .opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 18)

                    VStack(alignment: .leading, spacing: 14) {
                        Text(NSLocalizedString("compose.scenario.title", comment: "").uppercased())
                            .font(.system(size: 12, weight: .bold)).tracking(1.5)
                            .foregroundStyle(FT.Palette.textMuted)
                        // model is a @State @Observable reference; an explicit Binding
                        // avoids the @Bindable-local/`return` dance in `body`.
                        ScenarioChips(selection: Binding(
                            get: { model.scenario },
                            set: { model.scenario = $0 }
                        ))
                    }
                    .opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 20)
                }
                .padding(.horizontal, FT.Layout.sideMargin)
                .padding(.top, 8)
                .padding(.bottom, 140)
            }

            VStack {
                Spacer()
                CTAButton(title: NSLocalizedString("compose.depart", comment: ""),
                          style: .primary, icon: "arrow.right",
                          action: { onDepart(model.makeTicket()) })
                    .padding(.horizontal, FT.Layout.sideMargin).padding(.bottom, 12)
                    .background(
                        LinearGradient(colors: [FT.Palette.black.opacity(0), FT.Palette.black],
                                       startPoint: .top, endPoint: .bottom)
                            .ignoresSafeArea().allowsHitTesting(false)
                    )
            }
            .opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 24)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(FT.Palette.white)
                }
            }
        }
        .onAppear {
            model.prepareHaptics()
            resolver.bootstrap()
            guard !appeared else { return }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) { appeared = true }
        }
        .onChange(of: resolver.cityName) { _, name in
            if let name, let coord = resolver.coordinate {
                model.setOrigin(city: name, coordinate: coord)
            }
        }
    }
}
```

- [ ] **Step 2: Swap the route in `ContentView.swift`**

Replace the `.compose` case body inside `RootView.destination(for:)` (currently builds `ComposeJourneyView`):

```swift
        case .compose:
            DurationPickerView(
                onDepart: { ticket in
                    path.append(Route.seatPicker(ticket))
                },
                onBack: { path.removeLast() }
            )
```

- [ ] **Step 3: VERIFY-BUILD** → `** BUILD SUCCEEDED **`.

- [ ] **Step 4: VERIFY-RUN — exercise the three-way sync** — launch in the sim, tap **Start**. Expected:
  - Title, radar, big readout + ruler, carousel, scenario chips, and a white **Depart** button at the bottom appear.
  - Dragging the ruler updates the readout, the needle, and recenters the carousel — all three stay in sync.
  - Tapping a radar pin or a card moves the ruler and the other controls to match. No flicker/oscillation.
  - **Depart** → SeatPicker → seat + mode → BoardingPass shows the chosen destination + duration → ride starts.

- [ ] **Step 5: Commit**

```bash
git add FocusTrain/Features/FocusSession/Views/DurationPickerView.swift FocusTrain/ContentView.swift
git commit -m "feat: DurationPickerView container + wire into RootView.compose"
```

---

## Task 8: Localization keys

Add the new `durationPicker.*` keys to the String Catalog. (`compose.scenario.title`, `compose.depart`, `compose.duration.minutes` already exist and are reused.)

**Files:**
- Modify: `FocusTrain/Resources/Localizable.xcstrings`

- [ ] **Step 1: Add keys**

Open `Localizable.xcstrings` in Xcode (the catalog editor) and add these keys, or add them to the JSON under `"strings"`. PT-BR is the base locale; provide an English value too if other keys do.

| Key | pt-BR | en |
|-----|-------|----|
| `durationPicker.title` | `Escolha seu destino` | `Choose your destination` |
| `durationPicker.minutes` | `min` | `min` |
| `durationPicker.ruler.a11yLabel` | `Duração da sessão` | `Session duration` |

JSON shape per key (matching the catalog's existing entries):
```json
"durationPicker.title" : {
  "localizations" : {
    "pt-BR" : { "stringUnit" : { "state" : "translated", "value" : "Escolha seu destino" } },
    "en" : { "stringUnit" : { "state" : "translated", "value" : "Choose your destination" } }
  }
}
```

- [ ] **Step 2: VERIFY-BUILD** → `** BUILD SUCCEEDED **`. Re-launch (VERIFY-RUN); expected: the title reads "Escolha seu destino" (not the raw key), ruler VoiceOver label is "Duração da sessão".

- [ ] **Step 3: Commit**

```bash
git add FocusTrain/Resources/Localizable.xcstrings
git commit -m "feat: durationPicker localization keys"
```

---

## Task 9: Retire `ComposeJourney*` + final verification

Now that nothing references them, remove the old compose screen and its view model.

**Files:**
- Delete: `FocusTrain/Features/FocusSession/Views/ComposeJourneyView.swift`
- Delete: `FocusTrain/Features/FocusSession/ViewModels/ComposeJourneyViewModel.swift`

- [ ] **Step 1: Confirm there are no remaining references**

```bash
cd /Users/guilhermehoffmann/Desktop/Projects/FocusTrain
grep -rn "ComposeJourney" FocusTrain --include=*.swift
```
Expected: no matches (only the two files themselves, which we delete next). If anything else references them, fix it before deleting.

- [ ] **Step 2: Delete the files**

```bash
git rm FocusTrain/Features/FocusSession/Views/ComposeJourneyView.swift \
       FocusTrain/Features/FocusSession/ViewModels/ComposeJourneyViewModel.swift
```
(Files are removed from the folders; the synced group drops them from the target automatically — no `.pbxproj` edit.)

- [ ] **Step 3: VERIFY-BUILD** → `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Full-flow VERIFY-RUN** — Start → DurationPicker (drag ruler, tap pin, tap card — all synced) → Depart → SeatPicker → BoardingPass (correct destination + minutes) → ride → arrival. Confirm no regressions.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "refactor: retire ComposeJourneyView/ViewModel (replaced by DurationPicker)"
```

---

## Self-review notes (spec coverage)

- Spec §1–§4 (theme/model/ladder/origin) → Tasks 1, 3.
- §3 single source of truth + loop guard → Task 3 (`select` dedup, `interactionSource`), Task 6 (`isSyncing`).
- §5 three controls → Tasks 4 (ruler), 5 (radar/pin), 6 (carousel/card), 7 (compose).
- §6 haptics → Task 2; wired in Tasks 3/4/7 (`prepareHaptics`, `tick` on real change).
- §7 a11y/Dynamic Type/macOS → Task 4 (`.adjustable`), Task 5 (pin traits); fonts are system/Dynamic-Type throughout; haptics no-op on macOS (Task 2).
- §8 stylized distance → `nominalKm` on cards (Task 6); boarding pass untouched.
- §9 edge cases: random-origin fallback (Task 3 init), dedup detents (Task 3), no echo (Tasks 3/6). **Reduce Motion** is a nice-to-have — current animations are short springs; if needed, gate the needle/scroll springs behind `@Environment(\.accessibilityReduceMotion)` (small follow-up, not blocking).
- §11 implementation order → Tasks 1→9 (Foundation-up).
```
