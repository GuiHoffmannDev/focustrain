# Camera Pill Half-Rounded Thumb Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the translucent active-circle in the SessionView camera pill with a solid sliding thumb whose outer corners hug the capsule curvature and inner corners stay small (spec: `docs/superpowers/specs/2026-06-10-camera-pill-thumb-design.md`).

**Architecture:** One new self-contained design-system component (`SessionSegmentedPill`) renders the glass capsule, the animated `UnevenRoundedRectangle` thumb, and two plain glyph buttons. One new solid color token. One call-site swap in `SessionView.runningRightColumn`. `SessionControlPill`/`SessionControlButton` are untouched.

**Tech Stack:** SwiftUI (iOS 26.5 target), existing FT design tokens, `ftGlassCapsule(liquid: true)` for the capsule chrome.

**Testing note:** The app has **no Xcode test target** (the SwiftPM `Tests/CitiesHarness` covers cities logic only — pure-logic files symlinked in; SwiftUI view code cannot go there). Verification for each task is therefore: simulator build via `xcodebuild … CODE_SIGNING_ALLOWED=NO` (CLI codesign fails on provenance xattr otherwise) + Xcode previews for visual checks. New `.swift` files land in the target automatically (synced file groups) — **never edit `project.pbxproj`**.

**Build command (used in every task):**

```bash
cd /Users/guilhermehoffmann/Desktop/Projects/FocusTrain && \
xcodebuild -project FocusTrain.xcodeproj -scheme FocusTrain \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO -quiet build
```

Expected: exit 0, no `error:` lines (warnings OK if pre-existing).

---

### Task 1: `controlThumb` color token

**Files:**
- Modify: `FocusTrain/Core/DesignSystem/Colors.swift` (after `controlActiveGlyph`, ~line 98)

- [ ] **Step 1: Add the token**

In `FT.Palette`, directly below `controlActiveGlyph`:

```swift
        /// Solid fill of the selected-segment thumb (SessionSegmentedPill).
        /// Deliberately opaque — the reference design uses a solid block;
        /// standalone toggles keep the translucent `controlActiveTint`.
        static let controlThumb       = Color(light: 0x1A1A2E, dark: 0xFFFFFF)
```

(The `Color(light:dark:)` initializer already exists in this file, alpha defaults to 1.)

- [ ] **Step 2: Build to verify**

Run the build command from the header. Expected: succeeds.

- [ ] **Step 3: Commit**

```bash
git add FocusTrain/Core/DesignSystem/Colors.swift
git commit -m "feat(ds): controlThumb token for segmented pill thumb"
```

---

### Task 2: `SessionSegmentedPill` component

**Files:**
- Create: `FocusTrain/Core/DesignSystem/Components/SessionSegmentedPill.swift`

- [ ] **Step 1: Create the component file**

Full contents:

```swift
import SwiftUI

/// Two-position vertical selector pill (session map camera). The selected
/// segment is a solid thumb whose outer corners hug the capsule curvature
/// (radius 24 = capsule 30 − inset 6, concentric) while the inner corners
/// stay small (radius 8), forming a horizontal division line mid-pill.
/// Selecting the other segment slides the thumb and morphs the radii.
///
/// Haptics and `withAnimation` belong to the call site (wrap them in the
/// `selection` binding's setter) so the component stays presentation-only.
struct SessionSegmentedPill: View {
    struct Option {
        let systemName: String
        let accessibilityLabel: String
    }

    /// 0 = top segment, 1 = bottom segment.
    @Binding var selection: Int
    let top: Option
    let bottom: Option

    // Metrics mirror SessionControlButton/SessionControlPill chrome:
    // 48pt glyph, 6pt inset/spacing → capsule 60 wide, radius 30.
    private let glyphSize: CGFloat = 48
    private let inset: CGFloat = 6
    private let spacing: CGFloat = 6
    private let outerRadius: CGFloat = 24
    private let innerRadius: CGFloat = 8
    /// Visual gap between the thumb's inner edge and the pill's vertical
    /// centre — keeps the division line reading as a line, not a seam.
    private let centerGap: CGFloat = 4

    private var thumbHeight: CGFloat {
        (glyphSize * 2 + spacing - centerGap) / 2
    }

    private var thumbRadii: RectangleCornerRadii {
        selection == 0
            ? RectangleCornerRadii(topLeading: outerRadius,
                                   bottomLeading: innerRadius,
                                   bottomTrailing: innerRadius,
                                   topTrailing: outerRadius)
            : RectangleCornerRadii(topLeading: innerRadius,
                                   bottomLeading: outerRadius,
                                   bottomTrailing: outerRadius,
                                   topTrailing: innerRadius)
    }

    var body: some View {
        VStack(spacing: spacing) {
            segmentButton(0, top)
            segmentButton(1, bottom)
        }
        .padding(inset)
        .background { thumb }
        .background {
            Capsule()
                .fill(.clear)
                .ftGlassCapsule(liquid: true)
        }
    }

    private var thumb: some View {
        UnevenRoundedRectangle(cornerRadii: thumbRadii, style: .continuous)
            .fill(FT.Palette.controlThumb)
            .frame(width: glyphSize, height: thumbHeight)
            .padding(inset)
            .frame(maxHeight: .infinity,
                   alignment: selection == 0 ? .top : .bottom)
    }

    private func segmentButton(_ index: Int, _ option: Option) -> some View {
        let isSelected = selection == index
        return Button {
            selection = index
        } label: {
            Image(systemName: option.systemName)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(isSelected ? FT.Palette.controlActiveGlyph
                                            : FT.Palette.textPrimary)
                .frame(width: glyphSize, height: glyphSize)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(option.accessibilityLabel)
        .accessibilityValue(isSelected ? "on" : "off")
    }
}

#Preview("Selector") {
    @Previewable @State var selection = 0
    ZStack {
        FT.Palette.bgElevated.ignoresSafeArea()
        SessionSegmentedPill(
            selection: Binding(
                get: { selection },
                set: { value in
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
                        selection = value
                    }
                }
            ),
            top: .init(systemName: "point.topleft.down.to.point.bottomright.curvepath",
                       accessibilityLabel: "Fit route"),
            bottom: .init(systemName: "scope",
                          accessibilityLabel: "Center train")
        )
    }
}

#Preview("Selector — Light") {
    @Previewable @State var selection = 1
    ZStack {
        FT.Palette.bgElevated.ignoresSafeArea()
        SessionSegmentedPill(
            selection: Binding(
                get: { selection },
                set: { value in
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
                        selection = value
                    }
                }
            ),
            top: .init(systemName: "point.topleft.down.to.point.bottomright.curvepath",
                       accessibilityLabel: "Fit route"),
            bottom: .init(systemName: "scope",
                          accessibilityLabel: "Center train")
        )
    }
    .preferredColorScheme(.light)
}
```

Layering note (why two `.background`s): the first `.background` puts the thumb directly behind the glyphs; the second puts the glass capsule behind the thumb. The thumb is a plain solid fill, so it does not nest glass inside glass (the constraint that shaped `SessionControlButton`'s `grouped` mode).

- [ ] **Step 2: Build to verify**

Run the build command from the header. Expected: succeeds (file joins the target automatically via synced file groups).

- [ ] **Step 3: Visual check in Xcode previews**

Open both previews. Verify against the spec's success criteria:
- Thumb hugs the capsule top (selection 0) / bottom (selection 1); inner edge is a near-straight line with small (8pt) corners just below/above the pill's middle.
- Tapping the idle glyph slides the thumb across and the corner radii morph (no cross-fade, no shape glitch).
- Dark scheme: white thumb, ink glyph. Light scheme: ink thumb, white glyph.

- [ ] **Step 4: Commit**

```bash
git add FocusTrain/Core/DesignSystem/Components/SessionSegmentedPill.swift
git commit -m "feat(ds): SessionSegmentedPill with half-rounded sliding thumb"
```

---

### Task 3: Swap the camera pill call site in SessionView

**Files:**
- Modify: `FocusTrain/Features/FocusSession/Views/SessionView.swift:262-288` (`runningRightColumn`)

- [ ] **Step 1: Replace the SessionControlPill block**

Replace this existing block at the top of `runningRightColumn`'s `VStack` (the `map` and `train.side.rear.car` buttons below it stay untouched):

```swift
            SessionControlPill {
                SessionControlButton(
                    systemName: "point.topleft.down.to.point.bottomright.curvepath",
                    state: cameraMode == .fitRoute ? .active : .idle,
                    accessibilityLabel: NSLocalizedString("session.fit.route", comment: ""),
                    accessibilityValue: cameraMode == .fitRoute ? "on" : "off"
                ) {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
                        cameraMode = .fitRoute
                    }
                }

                SessionControlButton(
                    systemName: "scope",
                    state: cameraMode == .centerTrain ? .active : .idle,
                    accessibilityLabel: NSLocalizedString("session.center.train", comment: ""),
                    accessibilityValue: cameraMode == .centerTrain ? "on" : "off"
                ) {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
                        cameraMode = .centerTrain
                    }
                }
            }
```

with:

```swift
            SessionSegmentedPill(
                selection: Binding(
                    get: { cameraMode == .fitRoute ? 0 : 1 },
                    set: { index in
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
                            cameraMode = index == 0 ? .fitRoute : .centerTrain
                        }
                    }
                ),
                top: .init(
                    systemName: "point.topleft.down.to.point.bottomright.curvepath",
                    accessibilityLabel: NSLocalizedString("session.fit.route", comment: "")
                ),
                bottom: .init(
                    systemName: "scope",
                    accessibilityLabel: NSLocalizedString("session.center.train", comment: "")
                )
            )
```

Behaviour preserved: light haptic on every tap (including re-selecting, as today), same spring, same a11y labels, value `on`/`off`. `cameraMode` starts at `.centerTrain`, so the thumb starts on the bottom segment.

- [ ] **Step 2: Build to verify**

Run the build command from the header. Expected: succeeds.

- [ ] **Step 3: Visual check on the session screen**

Xcode preview of `SessionView` if available, otherwise run on simulator: start a session, confirm the camera pill shows the solid thumb (bottom = center-train initially), toggling slides it, and pause/music/map/tunnel buttons look unchanged.

- [ ] **Step 4: Commit**

```bash
git add FocusTrain/Features/FocusSession/Views/SessionView.swift
git commit -m "feat(session): camera pill uses half-rounded thumb selector"
```
