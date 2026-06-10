# Steam-Train Seat Picker Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rework `SeatPickerView` into a scrollable top-down steam train where the tapped seat morphs into the focus-reason modal, the chosen mode's icon fills the seat, and a Confirm pill launches a fast "train departing upward" animation into the existing BoardingPass flow.

**Architecture:** One vertical `ScrollView` containing the whole train (locomotive + 20-row carriage) as a continuous composition. A `matchedGeometryEffect` namespace shared between the seat tile (source, in scroll content) and the modal card (destination, root overlay) drives the hero morph. A small phase state machine in `SeatPickerView` (`idle → choosing(seat) → filled(seat) → departing(seat)`) orchestrates everything. The departure run translates the scroll content upward with an animated `.offset` while a `Canvas`-based overlay draws speed lines.

**Tech Stack:** SwiftUI (iOS 26 project), SwiftData `@Query` (unchanged), Swift Testing in the SwiftPM harness `Tests/CitiesHarness` (symlinks into app sources). Frosted-material surfaces via `ftGlassRounded` — **no** `liquid: true` here (selective-glass policy).

**Spec:** `docs/superpowers/specs/2026-06-10-train-seat-picker-redesign-design.md`

**Build command (simulator, CodeSign disabled — CLI signing fails on provenance xattr):**
```bash
xcodebuild -project FocusTrain.xcodeproj -scheme FocusTrain \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

**Test command:**
```bash
cd Tests/CitiesHarness && swift test
```

**Repo conventions:** new `.swift` files under `FocusTrain/` are picked up automatically by Xcode synced file groups — NEVER edit `project.pbxproj`. Work from repo root `/Users/guilhermehoffmann/conductor/workspaces/FocusTrain/amarillo`.

---

## File structure

| File | Action | Responsibility |
|---|---|---|
| `FocusTrain/Features/TrainTicket/Models/WagonLayout.swift` | Modify | 20 rows instead of 7 |
| `Tests/CitiesHarness/Sources/CitiesKit/WagonLayout.swift` | Create (symlink) | expose model to harness |
| `Tests/CitiesHarness/Tests/CitiesKitTests/WagonLayoutTests.swift` | Create | layout/codes unit tests |
| `FocusTrain/Resources/Localizable.xcstrings` | Modify | add modal/confirm keys; retire old confirm keys |
| `FocusTrain/Features/TrainTicket/Views/Components/SeatTile.swift` | Modify | `filled(symbol:tint:)` state, no in-tile letter |
| `FocusTrain/Features/TrainTicket/Views/Components/SteamLocomotiveView.swift` | Create | top-down locomotive + steam puffs + coupling |
| `FocusTrain/Features/TrainTicket/Views/Components/WagonView.swift` | Modify | 20-row carriage, aisle row numbers, header letters, tail, seat anchors + hero source |
| `FocusTrain/Features/TrainTicket/Views/Components/FocusReasonCard.swift` | Create | morph modal (seat code + prompt + chips) |
| `FocusTrain/Features/TrainTicket/Views/Components/SpeedLinesOverlay.swift` | Create | departure speed lines |
| `FocusTrain/Features/TrainTicket/Views/SeatPickerView.swift` | Modify (rewrite) | phase machine, scrim, morph, Confirm pill, departure run |
| `FocusTrain/Features/TrainTicket/Views/Components/SeatConfirmCard.swift` | Delete | superseded by `FocusReasonCard` + Confirm pill |

Untouched: `FocusMode.swift`, `CustomFocusModeSheet.swift`, `FocusModeChips.swift`, `FocusModeStore.swift`, `SeatHistory.swift`, `Ticket`, `BoardingPassView`, `ContentView`.

---

### Task 1: WagonLayout grows to 20 rows (TDD)

**Files:**
- Create: `Tests/CitiesHarness/Sources/CitiesKit/WagonLayout.swift` (symlink)
- Create: `Tests/CitiesHarness/Tests/CitiesKitTests/WagonLayoutTests.swift`
- Modify: `FocusTrain/Features/TrainTicket/Models/WagonLayout.swift:10-15`

- [ ] **Step 1: Symlink the model into the harness** (it imports Foundation only, so it compiles on macOS)

```bash
ln -s ../../../../FocusTrain/Features/TrainTicket/Models/WagonLayout.swift \
  Tests/CitiesHarness/Sources/CitiesKit/WagonLayout.swift
```

- [ ] **Step 2: Write the failing test**

Create `Tests/CitiesHarness/Tests/CitiesKitTests/WagonLayoutTests.swift`:

```swift
import Testing
@testable import CitiesKit

@Suite struct WagonLayoutTests {
    @Test func standardLayoutHasTwentyRows() {
        #expect(WagonLayout.standard.rows == 1...20)
    }

    @Test func seatCodesAreZeroPadded() {
        #expect(WagonLayout.seatCode(row: 1, column: "A") == "01A")
        #expect(WagonLayout.seatCode(row: 12, column: "C") == "12C")
        #expect(WagonLayout.seatCode(row: 20, column: "F") == "20F")
    }

    @Test func legacySevenRowCodesRemainValid() {
        // Journeys recorded before the 20-row carriage used rows 01–07; their
        // codes must still exist in the new layout so SeatHistory tinting works.
        let layout = WagonLayout.standard
        let all = Set(layout.rows.flatMap { row in
            layout.allColumns.map { WagonLayout.seatCode(row: row, column: $0) }
        })
        for row in 1...7 {
            for column in ["A", "C", "D", "F"] {
                #expect(all.contains(WagonLayout.seatCode(row: row, column: column)))
            }
        }
    }
}
```

- [ ] **Step 3: Run the test to verify it fails**

Run: `cd Tests/CitiesHarness && swift test --filter WagonLayoutTests`
Expected: FAIL — `standardLayoutHasTwentyRows` (`1...7 != 1...20`). The other two pass.

- [ ] **Step 4: Update the model**

In `FocusTrain/Features/TrainTicket/Models/WagonLayout.swift`, change the doc comment and `standard`:

```swift
/// Static description of the carriage used in `SeatPickerView`.
/// Two pairs of columns (A C | D F) split by a central aisle, 20 rows.
struct WagonLayout {
    let rows: ClosedRange<Int>
    let leftColumns: [String]
    let rightColumns: [String]

    static let standard = WagonLayout(
        rows: 1...20,
        leftColumns: ["A", "C"],
        rightColumns: ["D", "F"]
    )
```

(Keep `allColumns`, `rowLabel`, `seatCode` exactly as they are.)

- [ ] **Step 5: Run the tests to verify they pass**

Run: `cd Tests/CitiesHarness && swift test --filter WagonLayoutTests`
Expected: 3 tests PASS.

- [ ] **Step 6: Commit**

```bash
git add FocusTrain/Features/TrainTicket/Models/WagonLayout.swift Tests/CitiesHarness
git commit -m "feat(seatPicker): grow wagon layout to 20 rows with harness tests"
```

---

### Task 2: Localization keys for the modal and Confirm

**Files:**
- Modify: `FocusTrain/Resources/Localizable.xcstrings`

- [ ] **Step 1: Add the three new keys**

The file is JSON with `" : "` separators and sorted keys (Xcode style). Add keys with this script from repo root:

```bash
python3 - <<'EOF'
import json
path = 'FocusTrain/Resources/Localizable.xcstrings'
with open(path) as f:
    d = json.load(f)

def entry(en, pt):
    return {"extractionState": "manual", "localizations": {
        "en":    {"stringUnit": {"state": "translated", "value": en}},
        "pt-BR": {"stringUnit": {"state": "translated", "value": pt}},
    }}

d['strings']['seatPicker.modal.seat']  = entry("Seat: %@", "Assento: %@")
d['strings']['seatPicker.modal.title'] = entry("What do you want to focus?", "O que você quer focar?")
d['strings']['seatPicker.confirmCta']  = entry("Confirm", "Confirmar")

with open(path, 'w') as f:
    json.dump(d, f, ensure_ascii=False, indent=2, separators=(',', ' : '), sort_keys=True)
    f.write('\n')
EOF
```

- [ ] **Step 2: Verify the diff is additive only**

Run: `git diff --stat FocusTrain/Resources/Localizable.xcstrings`
Expected: a small diff (~30 added lines). If the whole file rewrote (thousands of changed lines), the separator/indent didn't match — inspect `git diff` and adjust the dump flags until only the new keys appear.

- [ ] **Step 3: Build to confirm the catalog still parses**

Run: `xcodebuild -project FocusTrain.xcodeproj -scheme FocusTrain -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`
Expected: BUILD SUCCEEDED.

- [ ] **Step 4: Commit**

```bash
git add FocusTrain/Resources/Localizable.xcstrings
git commit -m "feat(seatPicker): add modal and confirm localization keys"
```

---

### Task 3: SeatTile gains the `filled` state

**Files:**
- Modify: `FocusTrain/Features/TrainTicket/Views/Components/SeatTile.swift` (full replacement)
- Modify: `FocusTrain/Features/TrainTicket/Views/Components/WagonView.swift:95-105` (transitional shim so the build stays green)

- [ ] **Step 1: Replace SeatTile.swift entirely**

```swift
import SwiftUI
import UIKit

/// Single seat in the carriage grid. All states share the same footprint so
/// the layout never reflows when selection changes. Tiles are clean rounded
/// squares — the column letters live in the carriage header row instead.
struct SeatTile: View {
    enum State: Equatable {
        case available
        case previouslyUsed                       // occupied in a past journey
        case filled(symbol: String, tint: Color)  // carries the chosen focus mode
    }

    static let size: CGFloat = 48

    let code: String
    let state: State
    let onTap: () -> Void

    var body: some View {
        Button(action: handleTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.clear)
                    .ftGlassRounded(cornerRadius: 12, interactive: true, tint: glassTint)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(strokeColor, lineWidth: 1)
                    )

                if case .filled(let symbol, _) = state {
                    Image(systemName: symbol)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(FT.Palette.ink)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(width: Self.size, height: Self.size)
            .scaleEffect(isFilled ? 1.06 : 1.0)
            .shadow(color: shadowColor, radius: 8, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(code))
        .accessibilityAddTraits(isFilled ? .isSelected : [])
    }

    private var isFilled: Bool {
        if case .filled = state { return true }
        return false
    }

    private func handleTap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        onTap()
    }

    private var glassTint: Color? {
        switch state {
        case .available:           return nil
        case .previouslyUsed:      return FT.Palette.brandRail.opacity(0.18)
        case .filled(_, let tint): return tint
        }
    }

    private var strokeColor: Color {
        switch state {
        case .available:      return FT.Palette.textMuted.opacity(0.3)
        case .previouslyUsed: return FT.Palette.brandRail.opacity(0.45)
        case .filled:         return .clear
        }
    }

    private var shadowColor: Color {
        if case .filled(_, let tint) = state { return tint.opacity(0.35) }
        return .clear
    }
}
```

Notes: non-`liquid` `ftGlassRounded` renders a **solid** tint fill (see `FTGlass.swift` docs) — exactly the reference look of the cream seat with the icon.

- [ ] **Step 2: Transitional shim in WagonView**

`WagonView.seatTile(row:column:)` still references the removed `.selected` case. Replace the state mapping inside that function (and only that) with:

```swift
    private func seatTile(row: Int, column: String) -> some View {
        let code = WagonLayout.seatCode(row: row, column: column)
        let state: SeatTile.State = {
            // Transitional until Task 5: a generic fill stands in for selection.
            if selectedSeat == code { return .filled(symbol: "scope", tint: FT.Palette.Scenario.sage) }
            if usedSeats.contains(code) { return .previouslyUsed }
            return .available
        }()
        return SeatTile(code: code, state: state) {
            onSelect(code)
        }
    }
```

- [ ] **Step 3: Build**

Run: `xcodebuild -project FocusTrain.xcodeproj -scheme FocusTrain -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`
Expected: BUILD SUCCEEDED.

- [ ] **Step 4: Commit**

```bash
git add FocusTrain/Features/TrainTicket/Views/Components/SeatTile.swift \
        FocusTrain/Features/TrainTicket/Views/Components/WagonView.swift
git commit -m "feat(seatPicker): seat tile filled state with mode icon and tint"
```

---

### Task 4: SteamLocomotiveView (locomotive + steam puffs + coupling)

**Files:**
- Create: `FocusTrain/Features/TrainTicket/Views/Components/SteamLocomotiveView.swift`

- [ ] **Step 1: Create the file**

```swift
import SwiftUI

/// Top-down steam locomotive that crowns the train composition: rounded
/// smokebox nose, chimney with a brass ring, steam dome, long boiler with
/// transverse bands, and the driver's cab at the rear. Pure chrome — no
/// interaction. Steam puffs rise from the chimney into the sky headroom;
/// `steamIntensity` ramps them up during the departure run.
struct SteamLocomotiveView: View {
    var steamIntensity: Double = 0.35   // 0...1

    static let height: CGFloat = 320

    private let skyHeadroom: CGFloat = 96
    private let cabHeight: CGFloat = 84
    private let boilerWidthRatio: CGFloat = 0.58
    private let cabWidthRatio: CGFloat = 0.86

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let bodyTop = skyHeadroom
            let boilerHeight = Self.height - skyHeadroom - cabHeight + 14
            let boilerWidth = w * boilerWidthRatio
            let cabWidth = w * cabWidthRatio
            let chimneyCenter = CGPoint(x: w / 2, y: bodyTop + 34)

            ZStack {
                // Boiler with rounded smokebox nose.
                BoilerShape()
                    .fill(FT.Palette.bgElevated.opacity(0.25))
                    .overlay(
                        BoilerShape().stroke(FT.Palette.textMuted.opacity(0.35), lineWidth: 1.5)
                    )
                    .frame(width: boilerWidth, height: boilerHeight)
                    .position(x: w / 2, y: bodyTop + boilerHeight / 2)

                // Transverse boiler bands.
                ForEach(0..<3, id: \.self) { i in
                    Rectangle()
                        .fill(FT.Palette.textMuted.opacity(0.3))
                        .frame(width: boilerWidth, height: 1)
                        .position(x: w / 2, y: bodyTop + boilerHeight * (0.45 + 0.17 * CGFloat(i)))
                }

                // Driver's cab.
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(FT.Palette.bgElevated.opacity(0.35))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(FT.Palette.textMuted.opacity(0.35), lineWidth: 1.5)
                    )
                    .frame(width: cabWidth, height: cabHeight)
                    .position(x: w / 2, y: Self.height - cabHeight / 2)

                // Cab roof hatch.
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(FT.Palette.textMuted.opacity(0.3), lineWidth: 1)
                    .frame(width: 46, height: 18)
                    .position(x: w / 2, y: Self.height - cabHeight / 2)

                // Steam dome (brass).
                Circle()
                    .fill(FT.Palette.brandBrass.opacity(0.18))
                    .overlay(Circle().stroke(FT.Palette.brandBrass.opacity(0.5), lineWidth: 1.5))
                    .frame(width: 22, height: 22)
                    .position(x: w / 2, y: bodyTop + boilerHeight * 0.58)

                // Chimney with brass ring, near the nose.
                Circle()
                    .fill(FT.Palette.bgElevated)
                    .overlay(Circle().stroke(FT.Palette.brandBrass, lineWidth: 2))
                    .frame(width: 30, height: 30)
                    .position(chimneyCenter)

                SteamPuffsView(intensity: steamIntensity, emitter: chimneyCenter)
            }
        }
        .frame(height: Self.height)
        .allowsHitTesting(false)
    }
}

/// Long rounded rectangle whose top edge is a semicircle — the smokebox nose.
private struct BoilerShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let r = rect.width / 2
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
        p.addArc(
            center: CGPoint(x: rect.midX, y: rect.minY + r),
            radius: r,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

/// Stateless steam puffs: each puff loops on its own period, rising and fading
/// above the emitter. Driven purely by the timeline clock — no @State.
private struct SteamPuffsView: View {
    let intensity: Double
    let emitter: CGPoint

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            Canvas { context, _ in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let count = 5
                for i in 0..<count {
                    let phaseOffset = Double(i) / Double(count)
                    let period = 2.6 - 1.4 * intensity
                    let progress = ((t / period) + phaseOffset).truncatingRemainder(dividingBy: 1)
                    let rise = 60.0 + 40.0 * intensity
                    let drift = sin((t + Double(i) * 7) * 0.8) * 6
                    let x = emitter.x + CGFloat(drift)
                    let y = emitter.y - 18 - CGFloat(progress * rise)
                    let radius = CGFloat(6 + progress * 14)
                    let alpha = (1 - progress) * (0.08 + 0.22 * intensity)
                    let rect = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
                    context.fill(Ellipse().path(in: rect), with: .color(FT.Palette.white.opacity(alpha)))
                }
            }
        }
        .allowsHitTesting(false)
    }
}

/// Small coupling drawn between the locomotive and the carriage.
struct TrainCouplingView: View {
    var body: some View {
        VStack(spacing: 3) {
            Capsule()
                .fill(FT.Palette.textMuted.opacity(0.45))
                .frame(width: 6, height: 14)
            Capsule()
                .fill(FT.Palette.textMuted.opacity(0.3))
                .frame(width: 14, height: 3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 2)
    }
}

#Preview {
    ZStack {
        FT.Palette.black.ignoresSafeArea()
        VStack(spacing: 0) {
            SteamLocomotiveView(steamIntensity: 0.35)
            TrainCouplingView()
        }
        .padding(.horizontal, 24)
    }
}
```

- [ ] **Step 2: Build**

Run: `xcodebuild -project FocusTrain.xcodeproj -scheme FocusTrain -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`
Expected: BUILD SUCCEEDED (synced file groups pick the file up automatically).

- [ ] **Step 3: Commit**

```bash
git add FocusTrain/Features/TrainTicket/Views/Components/SteamLocomotiveView.swift
git commit -m "feat(seatPicker): top-down steam locomotive with puffs and coupling"
```

---

### Task 5: WagonView becomes the 20-row carriage

**Files:**
- Modify: `FocusTrain/Features/TrainTicket/Views/Components/WagonView.swift` (full replacement)
- Modify: `FocusTrain/Features/TrainTicket/Views/SeatPickerView.swift:24,45-50` (transitional call-site update)

- [ ] **Step 1: Replace WagonView.swift entirely**

```swift
import SwiftUI

/// Preference key collecting each seat slot's bounds so the host view can
/// anchor the focus modal near the tapped seat (the anchor persists even while
/// the tile itself is hidden during the morph).
struct SeatBoundsKey: PreferenceKey {
    static let defaultValue: [String: Anchor<CGRect>] = [:]
    static func reduce(value: inout [String: Anchor<CGRect>],
                       nextValue: () -> [String: Anchor<CGRect>]) {
        value.merge(nextValue()) { $1 }
    }
}

/// Top-down passenger carriage: rounded-top body, 20 rows of seats split by a
/// central aisle — row numbers live in the aisle, column letters in a header
/// row — and a long rounded tail that closes the train at the bottom.
struct WagonView: View {
    let layout: WagonLayout
    let seatState: (String) -> SeatTile.State
    let hiddenSeat: String?          // slot kept empty while it morphs into the modal
    let namespace: Namespace.ID
    let onSelect: (String) -> Void

    private let seatSpacing: CGFloat = 12
    private let aisleWidth: CGFloat = 44
    private let rowVerticalSpacing: CGFloat = 14
    private let tailHeight: CGFloat = 110

    var body: some View {
        ZStack(alignment: .top) {
            CarriageShape(tailHeight: tailHeight)
                .fill(FT.Palette.bgElevated.opacity(0.25))
                .overlay(
                    CarriageShape(tailHeight: tailHeight)
                        .stroke(FT.Palette.textMuted.opacity(0.35), lineWidth: 1.5)
                )

            VStack(spacing: rowVerticalSpacing) {
                columnHeader
                    .padding(.top, 28)

                ForEach(Array(layout.rows), id: \.self) { row in
                    rowView(row)
                }

                Color.clear.frame(height: tailHeight - 24)
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Column header (A C | D F)

    private var columnHeader: some View {
        HStack(spacing: seatSpacing) {
            ForEach(layout.leftColumns, id: \.self) { letterLabel($0) }
            Color.clear.frame(width: aisleWidth, height: 1)
            ForEach(layout.rightColumns, id: \.self) { letterLabel($0) }
        }
    }

    private func letterLabel(_ letter: String) -> some View {
        Text(letter)
            .font(.system(size: 13, weight: .semibold, design: .monospaced))
            .foregroundStyle(FT.Palette.textMuted)
            .frame(width: SeatTile.size)
    }

    // MARK: - Rows

    private func rowView(_ row: Int) -> some View {
        HStack(spacing: seatSpacing) {
            ForEach(layout.leftColumns, id: \.self) { column in
                seatSlot(row: row, column: column)
            }

            Text(WagonLayout.rowLabel(row))
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(FT.Palette.textMuted)
                .frame(width: aisleWidth)

            ForEach(layout.rightColumns, id: \.self) { column in
                seatSlot(row: row, column: column)
            }
        }
    }

    private func seatSlot(row: Int, column: String) -> some View {
        let code = WagonLayout.seatCode(row: row, column: column)
        return Group {
            if hiddenSeat == code {
                Color.clear
            } else {
                SeatTile(code: code, state: seatState(code)) {
                    onSelect(code)
                }
                .matchedGeometryEffect(id: code, in: namespace)
            }
        }
        .frame(width: SeatTile.size, height: SeatTile.size)
        .anchorPreference(key: SeatBoundsKey.self, value: .bounds) { [code: $0] }
    }
}

/// Rounded-top carriage body with a long rounded tail (big U) at the bottom.
private struct CarriageShape: Shape {
    let tailHeight: CGFloat

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let topRadius: CGFloat = 36
        let tailTop = rect.maxY - tailHeight

        p.move(to: CGPoint(x: rect.minX, y: tailTop))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + topRadius))
        p.addQuadCurve(
            to: CGPoint(x: rect.minX + topRadius, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.minY)
        )
        p.addLine(to: CGPoint(x: rect.maxX - topRadius, y: rect.minY))
        p.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + topRadius),
            control: CGPoint(x: rect.maxX, y: rect.minY)
        )
        p.addLine(to: CGPoint(x: rect.maxX, y: tailTop))
        // Tail: one sweeping curve through the bottom center.
        p.addQuadCurve(
            to: CGPoint(x: rect.minX, y: tailTop),
            control: CGPoint(x: rect.midX, y: rect.maxY + tailHeight * 0.35)
        )
        p.closeSubpath()
        return p
    }
}
```

Note the removed pieces vs the old file: the airplane-style `WagonShape` nose (the locomotive replaces it), the dashed aisle guide, and the side row labels.

- [ ] **Step 2: Transitional call-site update in SeatPickerView**

The old call passes `selectedSeat`/`usedSeats`. Update `SeatPickerView`:

Add below the other `@State` properties (line ~22):

```swift
    @Namespace private var seatNamespace
```

Replace the `WagonView(...)` call (lines ~45-50) with:

```swift
                    WagonView(
                        layout: layout,
                        seatState: { code in
                            // Transitional until Task 7: generic fill for selection.
                            if selectedSeat == code {
                                return .filled(symbol: "scope", tint: FT.Palette.Scenario.sage)
                            }
                            if usedSeats.contains(code) { return .previouslyUsed }
                            return .available
                        },
                        hiddenSeat: nil,
                        namespace: seatNamespace,
                        onSelect: handleSeatTap
                    )
```

- [ ] **Step 3: Build**

Run: `xcodebuild -project FocusTrain.xcodeproj -scheme FocusTrain -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`
Expected: BUILD SUCCEEDED.

- [ ] **Step 4: Commit**

```bash
git add FocusTrain/Features/TrainTicket/Views/Components/WagonView.swift \
        FocusTrain/Features/TrainTicket/Views/SeatPickerView.swift
git commit -m "feat(seatPicker): 20-row carriage with aisle numbers and rounded tail"
```

---

### Task 6: FocusReasonCard (the morph modal)

**Files:**
- Create: `FocusTrain/Features/TrainTicket/Views/Components/FocusReasonCard.swift`

- [ ] **Step 1: Create the file**

```swift
import SwiftUI

/// The focus-reason modal the tapped seat morphs into: seat code, prompt and
/// the focus-mode chips. Pure surface — selection state lives in the host
/// (`SeatPickerView`), which commits as soon as either binding becomes non-nil.
struct FocusReasonCard: View {
    let seatCode: String
    @Binding var selectedDefault: FocusMode?
    @Binding var selectedCustomID: UUID?
    let customModes: [CustomFocusMode]
    let onTapAdd: () -> Void
    let onDeleteCustom: (CustomFocusMode) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(String(format: NSLocalizedString("seatPicker.modal.seat", comment: ""), seatCode))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(FT.Palette.textSecondary)
                Text(LocalizedStringKey("seatPicker.modal.title"))
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(FT.Palette.textPrimary)
            }

            FocusModeChips(
                selectedDefault: $selectedDefault,
                selectedCustomID: $selectedCustomID,
                customModes: customModes,
                onTapAdd: onTapAdd,
                onDeleteCustom: onDeleteCustom
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.clear)
                .ftGlassRounded(cornerRadius: 24)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(FT.Palette.textMuted.opacity(0.25), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.45), radius: 18, y: 10)
    }
}

#Preview {
    ZStack {
        FT.Palette.black.ignoresSafeArea()
        FocusReasonCard(
            seatCode: "01C",
            selectedDefault: .constant(nil),
            selectedCustomID: .constant(nil),
            customModes: [],
            onTapAdd: {},
            onDeleteCustom: { _ in }
        )
        .padding(.horizontal, 24)
    }
}
```

- [ ] **Step 2: Build**

Run: `xcodebuild -project FocusTrain.xcodeproj -scheme FocusTrain -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`
Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Commit**

```bash
git add FocusTrain/Features/TrainTicket/Views/Components/FocusReasonCard.swift
git commit -m "feat(seatPicker): focus-reason modal card"
```

---

### Task 7: SeatPickerView rewrite — phase machine, morph, Confirm pill

**Files:**
- Modify: `FocusTrain/Features/TrainTicket/Views/SeatPickerView.swift` (full replacement)
- Delete: `FocusTrain/Features/TrainTicket/Views/Components/SeatConfirmCard.swift`
- Modify: `FocusTrain/Resources/Localizable.xcstrings` (retire old keys)

- [ ] **Step 1: Replace SeatPickerView.swift entirely**

In this task `handleConfirm` presents the boarding pass directly; Task 8 inserts the departure run.

```swift
import SwiftUI
import SwiftData
import UIKit

/// Last step before the ride: a scrollable top-down steam train. Tap a seat
/// and it morphs into the focus-reason modal; the chosen mode's icon fills the
/// seat; Confirm hands the ticket to the boarding pass.
struct SeatPickerView: View {
    let incomingTicket: Ticket
    var onDepart: (Ticket) -> Void
    var onBack: () -> Void

    @Environment(FocusModeStore.self) private var focusModeStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query private var journeys: [Journey]

    /// Interaction phases. `choosing`/`filled`/`departing` carry the seat code.
    private enum Phase: Equatable {
        case idle
        case choosing(String)
        case filled(String)
        case departing(String)
    }

    @State private var phase: Phase = .idle
    @State private var selectedDefault: FocusMode?
    @State private var selectedCustomID: UUID?
    @State private var showCustomSheet = false
    @State private var appeared = false
    @State private var pendingBoardingPass: Ticket?

    @Namespace private var seatNamespace

    private let layout = WagonLayout.standard
    private let morphSpring = Animation.spring(response: 0.42, dampingFraction: 0.86)

    private var usedSeats: Set<String> {
        SeatHistory.usedSeatCodes(in: journeys)
    }

    private var chosenSeat: String? {
        if case .choosing(let code) = phase { return code }
        return nil
    }

    private var isDeparting: Bool {
        if case .departing = phase { return true }
        return false
    }

    private var isScrollLocked: Bool {
        switch phase {
        case .choosing, .departing: return true
        case .idle, .filled:        return false
        }
    }

    /// Symbol/tint/name of whichever mode is selected (default or custom).
    private var chosenMode: (symbol: String, tint: Color, name: String)? {
        if let mode = selectedDefault {
            return (mode.symbol, mode.tint, mode.rawValue)
        }
        if let id = selectedCustomID,
           let custom = focusModeStore.customModes.first(where: { $0.id == id }) {
            return (custom.symbol, custom.tint, custom.name)
        }
        return nil
    }

    var body: some View {
        ZStack {
            FT.Palette.black.ignoresSafeArea()
            backdropGlow

            ScrollView(showsIndicators: false) {
                trainComposition
                    .padding(.horizontal, FT.Layout.sideMargin)
                    .padding(.top, 8)
                    .padding(.bottom, 160)
                    .opacity(appeared ? 1 : 0)
                    .scaleEffect(appeared ? 1 : 0.96)
            }
            .scrollDisabled(isScrollLocked)

            confirmLayer
        }
        .overlayPreferenceValue(SeatBoundsKey.self) { anchors in
            modalOverlay(anchors)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                // Plain button: the iOS 26 toolbar supplies the Liquid Glass
                // chrome; a custom background here would double it.
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(FT.Palette.white)
                }
                .disabled(isDeparting)
                .accessibilityLabel(Text("common.back"))
            }
        }
        .fullScreenCover(item: $pendingBoardingPass) { ticket in
            BoardingPassView(
                ticket: ticket,
                onTearComplete: { confirmedTicket in
                    pendingBoardingPass = nil
                    onDepart(confirmedTicket)
                },
                onCancel: { handleBoardingPassCancel() }
            )
        }
        .sheet(isPresented: $showCustomSheet) {
            CustomFocusModeSheet { mode in
                focusModeStore.add(mode)
                selectedCustomID = mode.id   // commits via onChange below
                selectedDefault = nil
            }
        }
        .onChange(of: selectedDefault) { _, new in
            if new != nil { commitChoice() }
        }
        .onChange(of: selectedCustomID) { _, new in
            if new != nil { commitChoice() }
        }
        .onAppear {
            guard !appeared else { return }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                appeared = true
            }
        }
    }

    // MARK: - Backdrop

    private var backdropGlow: some View {
        RadialGradient(
            colors: [FT.Palette.brandRail.opacity(0.10), .clear],
            center: .top,
            startRadius: 0,
            endRadius: 420
        )
        .ignoresSafeArea()
    }

    // MARK: - Train

    private var trainComposition: some View {
        VStack(spacing: 0) {
            SteamLocomotiveView(steamIntensity: isDeparting ? 1.0 : 0.35)
            TrainCouplingView()
            WagonView(
                layout: layout,
                seatState: seatState,
                hiddenSeat: chosenSeat,
                namespace: seatNamespace,
                onSelect: handleSeatTap
            )
        }
    }

    private func seatState(_ code: String) -> SeatTile.State {
        let filledCode: String? = {
            switch phase {
            case .filled(let c), .departing(let c): return c
            default: return nil
            }
        }()
        if code == filledCode, let mode = chosenMode {
            return .filled(symbol: mode.symbol, tint: mode.tint)
        }
        if usedSeats.contains(code) { return .previouslyUsed }
        return .available
    }

    // MARK: - Modal overlay (scrim + morphing card)

    @ViewBuilder
    private func modalOverlay(_ anchors: [String: Anchor<CGRect>]) -> some View {
        GeometryReader { proxy in
            ZStack {
                if case .choosing(let code) = phase {
                    FT.Palette.black.opacity(0.55)
                        .ignoresSafeArea()
                        .contentShape(Rectangle())
                        .onTapGesture { cancelChoice() }
                        .transition(.opacity)

                    let cardWidth = proxy.size.width - FT.Layout.sideMargin * 2
                    let seatMidY = anchors[code].map { proxy[$0].midY } ?? proxy.size.height / 2
                    let y = min(max(seatMidY, 200), proxy.size.height - 220)

                    FocusReasonCard(
                        seatCode: code,
                        selectedDefault: $selectedDefault,
                        selectedCustomID: $selectedCustomID,
                        customModes: focusModeStore.customModes,
                        onTapAdd: { showCustomSheet = true },
                        onDeleteCustom: handleDeleteCustom
                    )
                    .frame(width: cardWidth)
                    .matchedGeometryEffect(id: code, in: seatNamespace)
                    .position(x: proxy.size.width / 2, y: y)
                }
            }
        }
    }

    // MARK: - Confirm pill

    private var confirmLayer: some View {
        VStack {
            Spacer()
            if case .filled = phase, chosenMode != nil {
                CTAButton(
                    title: NSLocalizedString("seatPicker.confirmCta", comment: ""),
                    style: .primary,
                    action: handleConfirm
                )
                .padding(.horizontal, FT.Layout.sideMargin)
                .padding(.bottom, 12)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.82), value: phase)
    }

    // MARK: - Actions

    private func handleSeatTap(_ code: String) {
        guard !isDeparting else { return }
        // Tapping any seat (including a re-tap on the filled one) clears the
        // previous pick and opens the modal there — single selection.
        selectedDefault = nil
        selectedCustomID = nil
        withAnimation(morphSpring) {
            phase = .choosing(code)
        }
    }

    private func cancelChoice() {
        selectedDefault = nil
        selectedCustomID = nil
        withAnimation(morphSpring) {
            phase = .idle
        }
    }

    /// A chip was picked while the modal is open: morph the card back into the
    /// seat, now filled with the mode's icon and tint.
    private func commitChoice() {
        guard case .choosing(let code) = phase else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(morphSpring) {
            phase = .filled(code)
        }
    }

    private func handleDeleteCustom(_ mode: CustomFocusMode) {
        if selectedCustomID == mode.id { selectedCustomID = nil }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            focusModeStore.remove(mode)
        }
    }

    private func handleConfirm() {
        guard case .filled(let seat) = phase, let mode = chosenMode else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        var finalTicket = incomingTicket
        finalTicket.seatCode = seat
        finalTicket.focusMode = mode.name

        phase = .departing(seat)
        pendingBoardingPass = finalTicket   // Task 8 inserts the departure run here
    }

    private func handleBoardingPassCancel() {
        pendingBoardingPass = nil
        if case .departing(let seat) = phase {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                phase = .filled(seat)
            }
        }
    }
}

extension Ticket: Identifiable {
    var id: String { code }
}
```

- [ ] **Step 2: Delete SeatConfirmCard and verify nothing references it**

```bash
rm FocusTrain/Features/TrainTicket/Views/Components/SeatConfirmCard.swift
grep -rn "SeatConfirmCard" FocusTrain --include='*.swift'
```
Expected: no matches.

- [ ] **Step 3: Retire the old localization keys**

First verify nothing references them:

```bash
grep -rn "seatPicker.confirm\.\|seatPicker.depart\|seatPicker.title" FocusTrain --include='*.swift'
```
Expected: no matches (the rewrite no longer renders the on-screen title; the `seatPicker.title` *key* stays in the catalog in case the header returns, only `confirm.*` and `depart` are removed). Then:

```bash
python3 - <<'EOF'
import json
path = 'FocusTrain/Resources/Localizable.xcstrings'
with open(path) as f:
    d = json.load(f)
for key in ['seatPicker.confirm.title', 'seatPicker.confirm.subtitle', 'seatPicker.depart']:
    d['strings'].pop(key, None)
with open(path, 'w') as f:
    json.dump(d, f, ensure_ascii=False, indent=2, separators=(',', ' : '), sort_keys=True)
    f.write('\n')
EOF
```

- [ ] **Step 4: Build**

Run: `xcodebuild -project FocusTrain.xcodeproj -scheme FocusTrain -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`
Expected: BUILD SUCCEEDED.

- [ ] **Step 5: Manual smoke test in the simulator**

Launch the app (Home → start → duration picker → seat picker) and verify:
- Train renders: locomotive with idle puffs, coupling, 20-row carriage, tail; scrolls smoothly.
- Tap a seat → scrim + card morphs out of the seat; the slot stays empty behind it.
- Tap the scrim → card morphs back, seat empty again.
- Pick a chip → card shrinks into the seat, icon + tint visible, Confirm pill slides up.
- Tap another seat → previous fill clears, modal opens on the new seat.
- "+" → custom sheet → save → seat fills with the custom mode, pill appears.
- Confirm → boarding pass appears; cancel (X) → back to the filled seat state.

- [ ] **Step 6: Commit**

```bash
git add -A FocusTrain
git commit -m "feat(seatPicker): seat-to-modal morph, filled seats and confirm pill"
```

---

### Task 8: Departure run — speed lines, offset run, haptics, Reduce Motion

**Files:**
- Create: `FocusTrain/Features/TrainTicket/Views/Components/SpeedLinesOverlay.swift`
- Modify: `FocusTrain/Features/TrainTicket/Views/SeatPickerView.swift`

- [ ] **Step 1: Create SpeedLinesOverlay.swift**

```swift
import SwiftUI

/// Full-screen streaks that sell the departure run: thin vertical lines rushing
/// downward while the train translates up. Stateless — driven by the timeline
/// clock; `progress` (0...1 over the run) ramps density and speed in.
struct SpeedLinesOverlay: View {
    let progress: Double

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let lineCount = 16
                for i in 0..<lineCount {
                    let seed = Double((i &* 2654435761) % 1000) / 1000.0
                    let x = CGFloat(seed) * size.width
                    let speed = 900.0 + seed * 900.0
                    let length = CGFloat(60 + seed * 140) * CGFloat(0.5 + progress)
                    let cycle = Double(size.height) + Double(length) * 2
                    let travelled = (t * speed * (0.3 + progress)).truncatingRemainder(dividingBy: cycle)
                    let y = CGFloat(travelled) - length
                    let alpha = (0.05 + 0.22 * progress) * (0.4 + seed * 0.6)
                    var path = Path()
                    path.move(to: CGPoint(x: x, y: y))
                    path.addLine(to: CGPoint(x: x, y: y + length))
                    context.stroke(path, with: .color(FT.Palette.white.opacity(alpha)), lineWidth: 1.5)
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

#Preview {
    ZStack {
        FT.Palette.black.ignoresSafeArea()
        SpeedLinesOverlay(progress: 1)
    }
}
```

- [ ] **Step 2: Add run state to SeatPickerView**

Below `@State private var pendingBoardingPass: Ticket?` add:

```swift
    @State private var departOffset: CGFloat = 0
    @State private var departProgress: Double = 0
    @State private var contentFade: Double = 1
    @State private var contentHeight: CGFloat = 0
    @State private var viewportHeight: CGFloat = 0
```

- [ ] **Step 3: Wire measurements and the overlay into `body`**

Replace the `ScrollView { ... }` block inside `body`'s `ZStack` with:

```swift
            ScrollView(showsIndicators: false) {
                trainComposition
                    .padding(.horizontal, FT.Layout.sideMargin)
                    .padding(.top, 8)
                    .padding(.bottom, 160)
                    .opacity(appeared ? 1 : 0)
                    .scaleEffect(appeared ? 1 : 0.96)
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: {
                        contentHeight = $0
                    }
                    .offset(y: departOffset)
            }
            .scrollDisabled(isScrollLocked)
            .opacity(contentFade)

            if isDeparting {
                SpeedLinesOverlay(progress: departProgress)
            }
```

And attach the viewport measurement to the outer `ZStack` (alongside `.overlayPreferenceValue`):

```swift
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: {
            viewportHeight = $0
        }
```

- [ ] **Step 4: Replace `handleConfirm` and `handleBoardingPassCancel`, add haptics helper**

```swift
    private func handleConfirm() {
        guard case .filled(let seat) = phase, let mode = chosenMode else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        var finalTicket = incomingTicket
        finalTicket.seatCode = seat
        finalTicket.focusMode = mode.name
        phase = .departing(seat)

        if reduceMotion {
            withAnimation(.easeInOut(duration: 0.3)) { contentFade = 0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
                pendingBoardingPass = finalTicket
            }
            return
        }

        // The run: heavy start, then full steam — train exits the screen top.
        let distance = contentHeight + viewportHeight
        withAnimation(.timingCurve(0.85, 0.0, 0.9, 0.4, duration: 1.4)) {
            departOffset = -distance
        }
        withAnimation(.easeIn(duration: 1.0)) { departProgress = 1 }
        scheduleDepartureHaptics()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.45) {
            pendingBoardingPass = finalTicket
        }
    }

    /// Light impacts at increasing pace — wheels biting as the train speeds up.
    private func scheduleDepartureHaptics() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        for delay in [0.25, 0.55, 0.8, 0.98, 1.12, 1.24] {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                guard isDeparting else { return }
                generator.impactOccurred(intensity: 0.6 + 0.4 * delay / 1.3)
            }
        }
    }

    private func handleBoardingPassCancel() {
        pendingBoardingPass = nil
        departProgress = 0
        contentFade = 1
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) { departOffset = 0 }
        if case .departing(let seat) = phase {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                phase = .filled(seat)
            }
        }
    }
```

- [ ] **Step 5: Build**

Run: `xcodebuild -project FocusTrain.xcodeproj -scheme FocusTrain -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`
Expected: BUILD SUCCEEDED.

- [ ] **Step 6: Manual verification in the simulator**

- Confirm → train rushes upward off-screen (~1.4s), speed lines streak, puffs intensify → boarding pass slides in.
- Cancel the boarding pass (X) → train is back in place (no animation glitch), seat still filled, Confirm pill visible.
- Settings → Accessibility → Reduce Motion ON → Confirm → content crossfades, no run.

- [ ] **Step 7: Commit**

```bash
git add FocusTrain/Features/TrainTicket/Views/Components/SpeedLinesOverlay.swift \
        FocusTrain/Features/TrainTicket/Views/SeatPickerView.swift
git commit -m "feat(seatPicker): departure run with speed lines, haptics and reduce-motion path"
```

---

### Task 9: Final verification

- [ ] **Step 1: Full test run**

Run: `cd Tests/CitiesHarness && swift test`
Expected: all suites pass (Cities, GreatCircle, Ladder, WagonLayout).

- [ ] **Step 2: Clean full build**

Run: `xcodebuild -project FocusTrain.xcodeproj -scheme FocusTrain -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`
Expected: BUILD SUCCEEDED with no new warnings about matchedGeometryEffect duplicates ("Multiple inserted views in matched geometry group" in the runtime log means a tile and the card were both marked source — re-check the `hiddenSeat` wiring).

- [ ] **Step 3: Full manual checklist (simulator)**

1. Home → start → duration → seat picker: train renders, idle puffs, scroll through 20 rows to the tail.
2. Morph open / scrim cancel / chip pick / re-pick another seat / custom mode add and delete.
3. Confirm → departure run → boarding pass → tear → session starts (full happy path).
4. Boarding pass cancel → returns to filled state.
5. Reduce Motion path.
6. Back chevron from seat picker mid-selection → returns to duration picker, no crash on re-entry.

- [ ] **Step 4: Verify clean tree**

Run: `git status`
Expected: clean (every task committed its changes).
