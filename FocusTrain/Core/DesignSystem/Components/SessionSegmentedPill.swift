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
