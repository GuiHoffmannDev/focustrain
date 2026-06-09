# Liquid Glass DS Consolidation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Consolidate the app's already-broad Liquid Glass usage onto one small `FTGlass` design-system layer (Approach C — hybrid), without changing how any screen looks.

**Architecture:** A single primitive `FTGlassSurface` becomes the only place `.glassEffect` is called. One `FTGlassButtonStyle` captures the repeated press-scale + haptic pattern. Thin semantic components (`FTGlassChip`, `FTGlassCardButton`) compose those two. The legacy `ftGlassCapsule/Circle/Rounded` extensions are reimplemented on top of the primitive so all 27 existing call sites keep compiling with zero visual delta. `FTGlassContainer` wraps sibling glass to stop double-blur.

**Tech Stack:** SwiftUI, iOS 26.5 deployment target (Liquid Glass APIs available unconditionally), UIKit (`UIImpactFeedbackGenerator`).

---

## Verification Approach (read first)

There is **no SwiftUI UI-test target**. `Tests/CitiesHarness` is a logic-only SwiftPM harness (Cities DB) and does not render views — do not add UI tests there. Every task is therefore verified by:

1. **Compile** — Simulator build with code signing disabled (per project memory: CLI builds fail CodeSign without it):

   ```bash
   xcodebuild -project FocusTrain.xcodeproj -scheme FocusTrain \
     -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
     CODE_SIGNING_ALLOWED=NO build 2>&1 | tail -20
   ```
   Expected: `** BUILD SUCCEEDED **`. (Adjust simulator name if `iPhone 16 Pro` is unavailable: `xcrun simctl list devices available`.)

2. **Screenshot diff** — for tasks touching a locked screen, capture before (git stash) and after, compare visually. Any visible delta on a locked screen = revert.

Because this is a no-logic refactor, tasks are *change → build → (screenshot) → commit*, not red-green TDD. Where a task changes shared API, the "test" is that dependent call sites still build unchanged.

**Locked screens (feel-only, no visible change):** `SessionView`, all Onboarding screens, `ArrivalView`, `SessionPauseMenu`, `BoardingPassView`, `SeatPickerView`.

---

## File Structure

**Create:**
- `FocusTrain/Core/DesignSystem/Components/FTGlass.swift` — the whole new layer: `FTGlassShape`, `FTGlassSurface` + `.ftGlass(...)`, `.ftGlassSelectionStroke(...)`, `FTGlassButtonStyle`, `FTGlassChip`, `FTGlassCardButton`, `FTGlassContainer`.

**Modify (Commit 1 — foundation):**
- `Core/DesignSystem/Components/CTAButton.swift` — move legacy `ftGlass*` extensions + `FTGlassIconButton` onto `FTGlassSurface`; `CTAButton` adopts `FTGlassButtonStyle`.
- `Core/DesignSystem/Components/SheetActionCard.swift` — becomes a caller of `FTGlassCardButton`.

**Modify (Commit 2 — chips/selectors):**
- `Core/DesignSystem/Components/ScenarioChips.swift`
- `Features/TrainTicket/Views/Components/FocusModeChips.swift`
- `Features/History/Views/HistoryView.swift` (`FilterChip`)
- `Features/Trends/TrendsSheet.swift` (`RangePicker`)
- `Features/Settings/Views/SettingsSheet.swift` (`PickerCard`)
- `Core/DesignSystem/Components/MapStyleSelector.swift`
- `Features/TrainTicket/Views/CustomFocusModeSheet.swift` (symbol/colour cells)
- `Core/DesignSystem/Components/SessionControlPill.swift` (+ container, feel-only)

**Modify (Commit 3 — edges & sheets):** onboarding screens, `SessionPauseMenu`, `ArrivalView`, `SoundOverlay`, and close/back buttons in `DurationPickerView`, `SeatPickerView`, `TrendsSheet`, `SettingsSheet`, `CityPickerView`, `CustomFocusModeSheet`, `OnboardingContainerView`, `BoardingPassView`.

---

## Reference: current palette values (do not redefine)

From `Core/DesignSystem/Colors.swift` / `Typography.swift`:
- `FT.Palette.white` = `#FFFFFF`, `FT.Palette.brandRail` = `#FFFFFF` (brand accent is white), `FT.Palette.ink` = `#1A1A2E`
- `FT.Palette.textPrimary` = `#FFFFFF`, `FT.Palette.textSecondary` = `#9CA3AF`, `FT.Palette.textMuted` = `#6B7280`
- `FT.Layout.ctaHeight` = `64`

---

# COMMIT 1 — Foundation

## Task 1: Create `FTGlass.swift` with `FTGlassSurface` + container

**Files:**
- Create: `FocusTrain/Core/DesignSystem/Components/FTGlass.swift`

- [ ] **Step 1: Create the file with the shape enum, primitive, selection-stroke, and container**

```swift
import SwiftUI
import UIKit

/// The shapes the glass layer supports. One case per clip shape used in the app.
enum FTGlassShape {
    case capsule
    case circle
    case rounded(CGFloat)

    /// Insettable shape used for both the glass clip and selection stroke.
    @ViewBuilder
    func strokeShape() -> some InsettableShape {
        switch self {
        case .capsule:            Capsule(style: .continuous)
        case .circle:             Circle()
        case .rounded(let r):     RoundedRectangle(cornerRadius: r, style: .continuous)
        }
    }
}

/// THE single Liquid Glass primitive. This is the only place in the app that
/// calls `.glassEffect(...)`. Everything else composes this.
///
/// - `interactive`: pass `true` only when the surface backs a tappable control.
/// - `tint`: an accent, never a flat fill — translucency is preserved.
/// - `selected`: applies the standard selection stroke + lift (see rules below).
struct FTGlassSurface: ViewModifier {
    let shape: FTGlassShape
    var interactive: Bool = false
    var tint: Color? = nil
    var selected: Bool = false

    func body(content: Content) -> some View {
        content
            .background { glass }
            .ftGlassSelectionStroke(isSelected: selected, shape: shape)
            .scaleEffect(selected ? 1.03 : 1.0)
    }

    @ViewBuilder
    private var glass: some View {
        switch shape {
        case .capsule:        clip(Capsule(style: .continuous))
        case .circle:         clip(Circle())
        case .rounded(let r): clip(RoundedRectangle(cornerRadius: r, style: .continuous))
        }
    }

    @ViewBuilder
    private func clip<S: Shape>(_ s: S) -> some View {
        // Mirrors the legacy ftGlass* matrix exactly so adopters see no delta.
        if interactive, let tint {
            s.fill(.clear).glassEffect(.regular.tint(tint).interactive(), in: s)
        } else if interactive {
            s.fill(.clear).glassEffect(.regular.interactive(), in: s)
        } else if let tint {
            s.fill(.clear).glassEffect(.regular.tint(tint), in: s)
        } else {
            s.fill(.clear).glassEffect(.regular, in: s)
        }
    }
}

extension View {
    /// Apply the glass primitive. Default args reproduce a plain `.regular` glass
    /// background, matching the legacy helpers.
    func ftGlass(_ shape: FTGlassShape,
                 interactive: Bool = false,
                 tint: Color? = nil,
                 selected: Bool = false) -> some View {
        modifier(FTGlassSurface(shape: shape, interactive: interactive, tint: tint, selected: selected))
    }

    /// The standard selection rim: bright `brandRail` 2pt when selected,
    /// hairline white-0.08 1pt otherwise. Single definition for every chip/cell.
    @ViewBuilder
    func ftGlassSelectionStroke(isSelected: Bool, shape: FTGlassShape) -> some View {
        let s = shape.strokeShape()
        overlay(
            s.strokeBorder(
                isSelected ? FT.Palette.brandRail.opacity(0.85) : FT.Palette.white.opacity(0.08),
                lineWidth: isSelected ? 2 : 1
            )
        )
    }
}

/// Thin wrapper over Apple's `GlassEffectContainer` so sibling glass elements
/// morph/blend instead of stacking blurs. Single place to tune grouping.
struct FTGlassContainer<Content: View>: View {
    var spacing: CGFloat? = nil
    @ViewBuilder var content: () -> Content

    var body: some View {
        GlassEffectContainer(spacing: spacing) {
            content()
        }
    }
}
```

- [ ] **Step 2: Build**

Run the Verification build command. Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Commit**

```bash
git add FocusTrain/Core/DesignSystem/Components/FTGlass.swift
git commit -m "feat(ds): add FTGlassSurface primitive + container"
```

---

## Task 2: Add `FTGlassButtonStyle` to `FTGlass.swift`

**Files:**
- Modify: `FocusTrain/Core/DesignSystem/Components/FTGlass.swift`

- [ ] **Step 1: Append the button style**

```swift
/// Captures the press-scale + haptic pattern previously hand-rolled (DragGesture
/// + @State pressed + UIImpactFeedbackGenerator) in CTAButton and SheetActionCard.
struct FTGlassButtonStyle: ButtonStyle {
    var shape: FTGlassShape
    var tint: Color? = nil
    var interactive: Bool = true
    var haptic: UIImpactFeedbackGenerator.FeedbackStyle? = .medium
    var pressedScale: CGFloat = 0.97

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .ftGlass(shape, interactive: interactive, tint: tint)
            .scaleEffect(configuration.isPressed ? pressedScale : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed, let haptic { UIImpactFeedbackGenerator(style: haptic).impactOccurred() }
            }
    }
}
```

- [ ] **Step 2: Build** — Verification build command. Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Commit**

```bash
git add FocusTrain/Core/DesignSystem/Components/FTGlass.swift
git commit -m "feat(ds): add FTGlassButtonStyle"
```

---

## Task 3: Add `FTGlassChip` to `FTGlass.swift`

This is the single definition of the chip selected/idle treatment (extracted from
`ScenarioChips`). `selectedScale` defaults to the standardized `1.03`; callers on
locked screens may override to preserve an exact look.

**Files:**
- Modify: `FocusTrain/Core/DesignSystem/Components/FTGlass.swift`

- [ ] **Step 1: Append the chip**

```swift
/// Capsule chip with the standard glass selected/idle treatment.
/// Selected: tint accent + brandRail 2pt rim + 1.03 lift + ink foreground.
/// Idle: plain glass + hairline rim + `idleForeground`.
struct FTGlassChip<Label: View>: View {
    var isSelected: Bool
    var tint: Color
    var idleForeground: Color = FT.Palette.textPrimary
    var selectedForeground: Color = FT.Palette.ink
    var selectedScale: CGFloat = 1.03
    var haptic: UIImpactFeedbackGenerator.FeedbackStyle? = .medium
    let action: () -> Void
    @ViewBuilder var label: () -> Label

    var body: some View {
        Button {
            if let haptic { UIImpactFeedbackGenerator(style: haptic).impactOccurred() }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { action() }
        } label: {
            label()
                .foregroundStyle(isSelected ? selectedForeground : idleForeground)
                .ftGlass(.capsule, interactive: true, tint: isSelected ? tint : nil)
                .ftGlassSelectionStroke(isSelected: isSelected, shape: .capsule)
                .scaleEffect(isSelected ? selectedScale : 1.0)
        }
        .buttonStyle(.plain)
    }
}
```

> Note: `.ftGlass(selected:)` is intentionally NOT used here because the chip needs
> its own foreground + custom `selectedScale`; it composes `ftGlass` (material) +
> `ftGlassSelectionStroke` directly. Keep `selected:` on `FTGlassSurface` for
> non-button surfaces that want the default treatment.

- [ ] **Step 2: Build** — Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Commit**

```bash
git add FocusTrain/Core/DesignSystem/Components/FTGlass.swift
git commit -m "feat(ds): add FTGlassChip"
```

---

## Task 4: Add `FTGlassCardButton` to `FTGlass.swift`

Generalizes the `SheetActionCard` shape (leading icon badge, title/caption,
trailing chevron) using `FTGlassButtonStyle`.

**Files:**
- Modify: `FocusTrain/Core/DesignSystem/Components/FTGlass.swift`

- [ ] **Step 1: Append the card button**

```swift
/// Rounded glass row: leading icon badge, title + caption, trailing chevron.
/// The shape behind Home's History/Trends/Settings cards.
struct FTGlassCardButton: View {
    let title: String
    let caption: String
    let systemImage: String
    var cornerRadius: CGFloat = 20
    var accentTint: Color = FT.Palette.brandRail
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(accentTint.opacity(0.12))
                        .frame(width: 38, height: 38)
                    Image(systemName: systemImage)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(accentTint)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(FT.Palette.white)
                    Text(caption)
                        .font(.system(size: 12))
                        .foregroundStyle(FT.Palette.textSecondary)
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(FT.Palette.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
            )
        }
        .buttonStyle(FTGlassButtonStyle(shape: .rounded(cornerRadius), haptic: .light, pressedScale: 0.98))
    }
}
```

- [ ] **Step 2: Build** — Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Commit**

```bash
git add FocusTrain/Core/DesignSystem/Components/FTGlass.swift
git commit -m "feat(ds): add FTGlassCardButton"
```

---

## Task 5: Route legacy helpers + core components onto the new layer

Reimplement the three legacy extensions over `FTGlassSurface` (so all other call
sites are unchanged), adopt `FTGlassButtonStyle` in `CTAButton`, and make
`SheetActionCard` a caller of `FTGlassCardButton`.

**Files:**
- Modify: `FocusTrain/Core/DesignSystem/Components/CTAButton.swift`
- Modify: `FocusTrain/Core/DesignSystem/Components/SheetActionCard.swift`

- [ ] **Step 1: Replace the three legacy extensions in `CTAButton.swift`**

Replace the entire `extension View { func ftGlassCapsule ... ftGlassCircle ... ftGlassRounded ... }` block (currently lines ~109-149) with thin forwards to the primitive:

```swift
extension View {
    func ftGlassCapsule(interactive: Bool = false, tint: Color? = nil) -> some View {
        ftGlass(.capsule, interactive: interactive, tint: tint)
    }
    func ftGlassCircle(interactive: Bool = false, tint: Color? = nil) -> some View {
        ftGlass(.circle, interactive: interactive, tint: tint)
    }
    func ftGlassRounded(cornerRadius: CGFloat, interactive: Bool = false, tint: Color? = nil) -> some View {
        ftGlass(.rounded(cornerRadius), interactive: interactive, tint: tint)
    }
}
```

These previously called `.glassEffect` directly; now they delegate. Behavior is
identical (same matrix), so the 25 other call sites are visually unchanged.

- [ ] **Step 2: Convert `CTAButton` to `FTGlassButtonStyle`**

`CTAButton` keeps its loading/foreground logic but drops the hand-rolled
`@State pressed` + `DragGesture` + manual haptic. Replace the `body` and remove
the now-unused `pressed` state and `glassSurface` builder. New `body`:

```swift
var body: some View {
    Button(action: {
        guard !isLoading else { return }
        action()
    }) {
        ZStack {
            HStack(spacing: 8) {
                Text(title).font(FT.Typography.button)
                if let icon { Image(systemName: icon) }
            }
            .opacity(isLoading ? 0 : 1)

            if isLoading {
                ProgressView().progressViewStyle(.circular).tint(foreground)
            }
        }
        .foregroundStyle(foreground)
        .frame(maxWidth: .infinity)
        .frame(height: FT.Layout.ctaHeight)
        .overlay {
            if style == .ghost {
                Capsule().strokeBorder(FT.Palette.textMuted.opacity(0.32), lineWidth: 1)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isLoading)
    }
    .buttonStyle(FTGlassButtonStyle(shape: .capsule, tint: style == .primary ? FT.Palette.brandRail : nil))
    .disabled(isLoading)
}
```

Delete the `@State private var pressed = false` line and the entire
`@ViewBuilder private var glassSurface` block. Keep `foreground`.

> Visual check: primary keeps brandRail tint; secondary/ghost plain glass; ghost
> keeps its stroke. Press scale moves from 0.97 (unchanged). Haptic now fires via
> the style (`.medium`, same as before).

- [ ] **Step 3: Make `SheetActionCard` a caller**

Replace the entire body of `SheetActionCard` with a forward to `FTGlassCardButton`
(preserving its public init `title/caption/systemImage/action`):

```swift
struct SheetActionCard: View {
    let title: String
    let caption: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        FTGlassCardButton(title: title, caption: caption, systemImage: systemImage, action: action)
    }
}
```

Remove the old `@State pressed`, the `DragGesture`, and the inline layout.

- [ ] **Step 4: Build** — Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 5: Screenshot check (Home bottom stack + any CTA)**

Home's three cards and the primary CTA must look identical to before. Capture and
eyeball. If the card lift differs (0.98) or CTA tint shifts, reconcile before commit.

- [ ] **Step 6: Commit**

```bash
git add FocusTrain/Core/DesignSystem/Components/CTAButton.swift \
        FocusTrain/Core/DesignSystem/Components/SheetActionCard.swift
git commit -m "refactor(ds): route legacy glass helpers + CTAButton/SheetActionCard onto FTGlass layer"
```

---

# COMMIT 2 — Chips & selectors

## Task 6: Group `SessionControlPill` children in a container (feel-only, LOCKED)

`SessionView` is locked. The pill currently paints a glass capsule AND each child
paints a glass circle → double blur. Wrapping in `FTGlassContainer` lets them
morph instead. Composition stays identical.

**Files:**
- Modify: `FocusTrain/Core/DesignSystem/Components/SessionControlPill.swift`

- [ ] **Step 1: Wrap the stack in a container**

Change the `body` so the `VStack` + its glass background sit inside `FTGlassContainer`:

```swift
var body: some View {
    FTGlassContainer(spacing: 6) {
        VStack(spacing: 6) {
            content()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 6)
        .background {
            Capsule().fill(.clear).ftGlassCapsule()
        }
    }
}
```

- [ ] **Step 2: Build** — Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Screenshot check (LOCKED — SessionView)**

```bash
git stash && <build+screenshot baseline>; git stash pop && <build+screenshot after>
```
The pill must look the same minus the doubled blur. Any layout shift = revert.

- [ ] **Step 4: Commit**

```bash
git add FocusTrain/Core/DesignSystem/Components/SessionControlPill.swift
git commit -m "refactor(session): group control pill glass in FTGlassContainer (feel-only)"
```

---

## Task 7: `ScenarioChips` → `FTGlassChip`

**Files:**
- Modify: `FocusTrain/Core/DesignSystem/Components/ScenarioChips.swift`

- [ ] **Step 1: Replace `chip(for:)` with `FTGlassChip`**

```swift
private func chip(for scenario: FocusScenario) -> some View {
    FTGlassChip(
        isSelected: selection == scenario,
        tint: scenario.tint,
        action: { selection = scenario }
    ) {
        HStack(spacing: 10) {
            Image(systemName: scenario.symbol)
                .font(.system(size: 16, weight: .semibold))
            Text(LocalizedStringKey(scenario.displayKey))
                .font(.system(size: 16, weight: .semibold))
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
```

- [ ] **Step 2: Wrap the grid in a container** — change `LazyVGrid(...) { ... }` to be wrapped:

```swift
FTGlassContainer {
    LazyVGrid(columns: columns, spacing: 12) {
        ForEach(FocusScenario.allCases) { scenario in
            chip(for: scenario)
        }
    }
}
```

- [ ] **Step 3: Build** — Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Screenshot check** — chips identical (selected lift was already 1.03).

- [ ] **Step 5: Commit**

```bash
git add FocusTrain/Core/DesignSystem/Components/ScenarioChips.swift
git commit -m "refactor(ds): ScenarioChips uses FTGlassChip + container"
```

---

## Task 8: `FocusModeChips` → `FTGlassChip`

**Files:**
- Modify: `FocusTrain/Features/TrainTicket/Views/Components/FocusModeChips.swift`

- [ ] **Step 1: Replace `chipLabel` usage with `FTGlassChip`** in both `defaultChip` and `customChip`. Replace `defaultChip`:

```swift
private func defaultChip(_ mode: FocusMode) -> some View {
    FTGlassChip(
        isSelected: selectedDefault == mode,
        tint: mode.tint,
        selectedScale: 1.03,
        action: { selectedDefault = mode; selectedCustomID = nil }
    ) {
        chipContent(symbol: mode.symbol, text: LocalizedStringKey(mode.displayKey))
    }
}
```

Replace `customChip` similarly (keep its `.contextMenu`):

```swift
private func customChip(_ mode: CustomFocusMode) -> some View {
    FTGlassChip(
        isSelected: selectedCustomID == mode.id,
        tint: mode.tint,
        selectedScale: 1.03,
        action: { selectedCustomID = mode.id; selectedDefault = nil }
    ) {
        chipContent(symbol: mode.symbol, text: LocalizedStringKey(mode.name))
    }
    .contextMenu {
        Button(role: .destructive) { onDeleteCustom(mode) } label: {
            Label(LocalizedStringKey("focusMode.custom.delete"), systemImage: "trash")
        }
    }
}
```

Replace `chipLabel(...)` with a content-only helper (no glass/stroke/foreground —
`FTGlassChip` owns those):

```swift
private func chipContent(symbol: String, text: LocalizedStringKey) -> some View {
    HStack(spacing: 8) {
        Image(systemName: symbol).font(.system(size: 14, weight: .semibold))
        Text(text).font(.system(size: 14, weight: .semibold)).lineLimit(1)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
}
```

Delete the old `chipLabel` and the now-unused `tap` helper (its haptic + spring now
live in `FTGlassChip`).

> Standardization note: selected lift goes 1.04 → 1.03 (≤1px, imperceptible). If a
> screenshot shows a difference, pass `selectedScale: 1.04` to preserve exactly.

- [ ] **Step 2: Build** — Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Screenshot check** — chip row identical; `+` add chip untouched.

- [ ] **Step 4: Commit**

```bash
git add FocusTrain/Features/TrainTicket/Views/Components/FocusModeChips.swift
git commit -m "refactor(ticket): FocusModeChips uses FTGlassChip"
```

---

## Task 9: `FilterChip` → `FTGlassChip` (History)

**Files:**
- Modify: `FocusTrain/Features/History/Views/HistoryView.swift`

- [ ] **Step 1: Reimplement `FilterChip` body over `FTGlassChip`**

History is not locked, so it standardizes onto the canonical rim (brandRail 0.85,
was 0.6) and selected tint (`white 0.75`, preserved). Keep the public API.

```swift
private struct FilterChip: View {
    let label: String
    var systemImage: String? = nil
    var tint: Color = FT.Palette.brandRail
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        FTGlassChip(
            isSelected: isSelected,
            tint: FT.Palette.white.opacity(0.75),
            idleForeground: FT.Palette.textSecondary,
            selectedForeground: FT.Palette.black,
            haptic: nil,
            action: action
        ) {
            HStack(spacing: 6) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(isSelected ? FT.Palette.black : tint)
                }
                Text(label).font(FT.Typography.caption.weight(.semibold))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }
}
```

> The icon keeps its own `tint` foreground when idle (overrides the chip's
> `idleForeground`) — that's why the icon sets `.foregroundStyle` explicitly.

- [ ] **Step 2: Wrap the History filter bar in `FTGlassContainer`** — locate the
`HStack`/`ScrollView` that lays out the `FilterChip`s and wrap its content in
`FTGlassContainer { ... }`. (Read the surrounding filter-bar code first; wrap only
the chip row, not the whole screen.)

- [ ] **Step 3: Build** — Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Screenshot check** — filter bar reads the same; selected rim is now
slightly brighter (intended consistency change, History not locked).

- [ ] **Step 5: Commit**

```bash
git add FocusTrain/Features/History/Views/HistoryView.swift
git commit -m "refactor(history): FilterChip uses FTGlassChip + container"
```

---

## Task 10: Selectors → `FTGlassSurface` (`MapStyleSelector`, `RangePicker`, `PickerCard`)

These are not chips (different shapes/segmented), so they adopt `.ftGlass(...)` +
`.ftGlassSelectionStroke` rather than `FTGlassChip`. Behavior preserved.

**Files:**
- Modify: `FocusTrain/Core/DesignSystem/Components/MapStyleSelector.swift`
- Modify: `FocusTrain/Features/Trends/TrendsSheet.swift`
- Modify: `FocusTrain/Features/Settings/Views/SettingsSheet.swift`

- [ ] **Step 1: `MapStyleSelector.tile` — fold the manual overlay into the helper**

Replace the `.background(...)` + `.overlay(...)` pair on the tile with:

```swift
.background(EmptyView())
.ftGlass(.rounded(18), interactive: true, tint: isSelected ? FT.Palette.brandRail.opacity(0.28) : nil)
.ftGlassSelectionStroke(isSelected: isSelected, shape: .rounded(18))
```

Wrap the `LazyVGrid` of tiles in `FTGlassContainer { ... }` (leave `labelsToggle`
outside the container).

- [ ] **Step 2: `RangePicker` (TrendsSheet)** — wrap the `ZStack` in
`FTGlassContainer` so the track + moving thumb (two glass rects) morph instead of
double-blur. Replace the track's `.ftGlassRounded(...).overlay(stroke)` with
`.ftGlass(.rounded(14)).ftGlassSelectionStroke(isSelected: false, shape: .rounded(14))`
(the hairline rim). Thumb stays `.ftGlassRounded(cornerRadius: 11, tint: .white 0.75)`.

```swift
var body: some View {
    GeometryReader { geo in
        // ... unchanged let bindings ...
        FTGlassContainer {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.clear)
                    .ftGlass(.rounded(14))
                    .ftGlassSelectionStroke(isSelected: false, shape: .rounded(14))
                // ... thumb + HStack unchanged ...
            }
        }
    }
    .frame(height: 40)
}
```

- [ ] **Step 3: `PickerCard` (SettingsSheet)** — replace its trailing
`.background(...).overlay(stroke)` with the helper pair:

```swift
.ftGlass(.rounded(18))
.overlay(
    RoundedRectangle(cornerRadius: 18, style: .continuous)
        .strokeBorder(FT.Palette.white.opacity(0.06), lineWidth: 1)
)
```

(`PickerCard`'s rim is intentionally the softer `white 0.06`, not the chip rim —
it's a container, not a selectable chip. Leave it.)

- [ ] **Step 4: Build** — Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 5: Screenshot check** — Map style grid, Trends range segmented control,
Settings picker card all identical.

- [ ] **Step 6: Commit**

```bash
git add FocusTrain/Core/DesignSystem/Components/MapStyleSelector.swift \
        FocusTrain/Features/Trends/TrendsSheet.swift \
        FocusTrain/Features/Settings/Views/SettingsSheet.swift
git commit -m "refactor(ds): selectors adopt FTGlassSurface + selection stroke + containers"
```

---

## Task 11: `CustomFocusModeSheet` symbol/colour cells

**Files:**
- Modify: `FocusTrain/Features/TrainTicket/Views/CustomFocusModeSheet.swift`

- [ ] **Step 1: Read the current symbol-cell and colour-cell code**

Run: `grep -n "ftGlass\|glassEffect\|\.overlay\|strokeBorder\|isSelected" FocusTrain/Features/TrainTicket/Views/CustomFocusModeSheet.swift`
Identify the symbol grid cell and colour grid cell views.

- [ ] **Step 2: Apply the standard pattern to each cell**

For each selectable cell, replace its glass background + manual stroke with:

```swift
// symbol cell (square): shape .rounded(<existing radius>)
.ftGlass(.rounded(<r>), interactive: true, tint: isSelected ? <accent> : nil)
.ftGlassSelectionStroke(isSelected: isSelected, shape: .rounded(<r>))
// colour cell (circle):
.ftGlass(.circle, interactive: true, tint: isSelected ? color.opacity(0.45) : nil)
.ftGlassSelectionStroke(isSelected: isSelected, shape: .circle)
```

Use the cell's existing corner radius / accent. Colour cells soften tint to
`0.45` per the tint-as-accent rule (matches `SessionControlButton`).

- [ ] **Step 3: Wrap each grid in `FTGlassContainer`.**

- [ ] **Step 4: Build** — Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 5: Screenshot check** — symbol + colour pickers read the same; colour
selection is an accent rim + soft tint, not an opaque fill.

- [ ] **Step 6: Commit**

```bash
git add FocusTrain/Features/TrainTicket/Views/CustomFocusModeSheet.swift
git commit -m "refactor(ticket): custom-mode symbol/colour cells adopt FTGlass layer"
```

---

# COMMIT 3 — Edges & sheets

## Task 12: Migrate ad-hoc materials on edge surfaces

Replace ad-hoc `.ultraThinMaterial` / `.fill(Color...opacity)` glass backgrounds
with `.ftGlass(...)`. **Onboarding, ArrivalView, SessionPauseMenu are LOCKED** —
swap the material only, keep every dimension and colour. SoundOverlay is not
locked.

**Files (confirm exact sites first):**
- `Features/FocusSession/Views/Components/SoundOverlay.swift`
- `Features/FocusSession/Views/Components/SessionPauseMenu.swift` (LOCKED)
- `Features/FocusSession/Views/ArrivalView.swift` (LOCKED)
- `Features/Onboarding/Views/Screens/*.swift` (LOCKED)

- [ ] **Step 1: Enumerate sites**

Run:
```bash
grep -rn "ultraThinMaterial\|thinMaterial\|regularMaterial" \
  FocusTrain/Features/FocusSession/Views/Components/SoundOverlay.swift \
  FocusTrain/Features/FocusSession/Views/Components/SessionPauseMenu.swift \
  FocusTrain/Features/FocusSession/Views/ArrivalView.swift \
  FocusTrain/Features/Onboarding/Views/Screens
```

- [ ] **Step 2: For each card/panel site, swap the material for glass**

Pattern (apply per site, preserving the existing clip shape + radius):

```swift
// BEFORE
.background(
    RoundedRectangle(cornerRadius: R, style: .continuous)
        .fill(.ultraThinMaterial)
)
// AFTER
.background(
    RoundedRectangle(cornerRadius: R, style: .continuous).fill(.clear)
)
.ftGlass(.rounded(R))
```

Do NOT add `interactive:` to non-tappable panels. Do NOT add a selection stroke
unless the original had a matching border.

- [ ] **Step 3: Build** — Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Screenshot check (LOCKED screens)** — baseline-vs-after for each
onboarding screen, ArrivalView, SessionPauseMenu. The glass should read like the
prior material; any visible difference (more/less blur, tint) → keep the original
material for that specific site and note it.

- [ ] **Step 5: Commit**

```bash
git add -A FocusTrain/Features/FocusSession/Views FocusTrain/Features/Onboarding
git commit -m "refactor(edges): migrate ad-hoc materials to FTGlass (feel-only on locked screens)"
```

---

## Task 13: Standardize close/back buttons on `FTGlassIconButton`

Sheets with hand-rolled circular close/back buttons adopt the shared
`FTGlassIconButton`. SeatPicker & BoardingPass & CityPicker dismiss buttons are
feel-only if they're on locked screens — only swap if visually identical.

**Files (confirm each first):**
- `Features/FocusSession/Views/DurationPickerView.swift`
- `Features/TrainTicket/Views/SeatPickerView.swift` (LOCKED)
- `Features/TrainTicket/Views/CustomFocusModeSheet.swift`
- `Features/Trends/TrendsSheet.swift`
- `Features/Settings/Views/SettingsSheet.swift`
- `Features/Location/CityPickerView.swift`
- `Features/Onboarding/Views/OnboardingContainerView.swift` (LOCKED)
- `Features/BoardingPass/Views/BoardingPassView.swift` (LOCKED)

- [ ] **Step 1: Enumerate close/back buttons**

Run:
```bash
grep -rn "xmark\|chevron.left\|chevron.backward\|dismiss()" \
  FocusTrain/Features/FocusSession/Views/DurationPickerView.swift \
  FocusTrain/Features/TrainTicket/Views/SeatPickerView.swift \
  FocusTrain/Features/Trends/TrendsSheet.swift \
  FocusTrain/Features/Settings/Views/SettingsSheet.swift \
  FocusTrain/Features/Location/CityPickerView.swift \
  FocusTrain/Features/Onboarding/Views/OnboardingContainerView.swift \
  FocusTrain/Features/BoardingPass/Views/BoardingPassView.swift
```

- [ ] **Step 2: Replace each matching circular glass icon button**

For a button that is currently `Image(systemName: "xmark") ... .background(Circle()...ftGlassCircle...)`, replace with:

```swift
FTGlassIconButton(
    systemName: "xmark",
    accessibilityLabel: "common.close"   // reuse existing label key if present
) { dismiss() }
```

Keep the existing `size` / `iconSize` if the original differed from the 40/14
defaults (pass them explicitly to preserve the look). Skip any button already
using `FTGlassIconButton`.

- [ ] **Step 3: Build** — Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Screenshot check** — each sheet's close/back button identical;
verify accessibility labels preserved (VoiceOver rotor or `accessibilityLabel`
present in code).

- [ ] **Step 5: Commit**

```bash
git add -A FocusTrain/Features
git commit -m "refactor(sheets): standardize close/back buttons on FTGlassIconButton"
```

---

## Task 14: Final full-app verification pass

**Files:** none (verification only).

- [ ] **Step 1: Clean build**

Run the Verification build command. Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 2: Confirm single glassEffect call site**

Run: `grep -rn "\.glassEffect(" FocusTrain --include="*.swift"`
Expected: matches only inside `FTGlass.swift` (`FTGlassSurface`). Any other hit is
a missed migration — migrate it or document why it stays.

- [ ] **Step 3: Screenshot pass over all screens**

Capture: Onboarding, Home, DurationPicker, SeatPicker, BoardingPass, Session,
SoundOverlay, PauseMenu, Arrival, History, Trends, Settings, CityPicker. Check:
contrast over map/gradient, consistent shapes, and **no double-glass**. Locked
screens must match their baselines.

- [ ] **Step 4: Accessibility spot-check**

Run: `grep -rn "accessibilityLabel\|accessibilityValue\|.disabled(" FocusTrain/Core/DesignSystem/Components/SessionControlButton.swift FocusTrain/Core/DesignSystem/Components/CTAButton.swift`
Confirm labels/disabled preserved on migrated controls.

- [ ] **Step 5: Cities harness still green** (sanity — unaffected, but confirms no
shared breakage):

Run: `cd Tests/CitiesHarness && swift test 2>&1 | tail -5`
Expected: tests pass (unchanged by this UI work).

- [ ] **Step 6: Final commit (if any screenshot fixups were made)**

```bash
git add -A && git commit -m "chore(ds): final liquid glass consolidation verification fixups"
```

---

## Self-Review

**Spec coverage:**
- Formalize DS API → Tasks 1–5 (Surface, ButtonStyle, Chip, CardButton, Container; legacy helpers rerouted). ✓
- Finish the edges → Task 12 (ad-hoc materials), Task 13 (icon buttons). ✓
- Consistency pass → Tasks 7–11 (chips/selectors unified; selected/idle/disabled via single `ftGlassSelectionStroke` + `FTGlassChip`). ✓
- GlassEffectContainer grouping → Tasks 6, 7, 9, 10, 11 (pill, chip grids, filter bar, selectors). ✓
- Accessibility/contrast → Task 13 step 4, Task 14 steps 3–4. ✓
- Locked-screen safety → screenshot gates in Tasks 6, 8, 12, 13, 14. ✓

**Type consistency:** `FTGlassShape`, `.ftGlass(_:interactive:tint:selected:)`, `.ftGlassSelectionStroke(isSelected:shape:)`, `FTGlassButtonStyle(shape:tint:interactive:haptic:pressedScale:)`, `FTGlassChip(isSelected:tint:idleForeground:selectedForeground:selectedScale:haptic:action:label:)`, `FTGlassCardButton(title:caption:systemImage:cornerRadius:accentTint:action:)`, `FTGlassContainer(spacing:content:)` — used consistently across tasks. ✓

**Placeholder scan:** Tasks 11/12/13 contain "read the current code first" steps with `<r>`/`<accent>`/`R` placeholders — these are deliberate per-site values the engineer reads from the existing file, with the exact transformation pattern and grep command provided. Acceptable (the *recipe* is complete; only the file-specific literal is read in-place).

**Known standardization deltas (intended, non-locked screens only):** FocusModeChips lift 1.04→1.03; FilterChip rim 0.6→0.85. Both flagged with preserve-exact overrides if a screenshot shows a difference.
