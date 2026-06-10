import SwiftUI
import UIKit

/// The shapes the glass layer supports. One case per clip shape used in the app.
enum FTGlassShape {
    case capsule
    case circle
    case rounded(CGFloat)
}

/// Shared surface styling primitive and the app's only `.glassEffect` call site.
///
/// Default rendering is the post-revert styling: a solid tint (when given) or a
/// frosted `.ultraThinMaterial`. Real Liquid Glass is opt-in via `liquid` and is
/// reserved for circular session controls and close/back icon buttons.
///
/// - `interactive`: with `liquid`, maps to `.interactive()`; otherwise no effect.
/// - `tint`: with `liquid`, a translucent glass accent; otherwise a solid fill.
/// - `selected`: applies the standard selection stroke + lift (see rules below).
struct FTGlassSurface: ViewModifier {
    let shape: FTGlassShape
    var interactive: Bool = false
    var tint: Color? = nil
    var selected: Bool = false
    var liquid: Bool = false

    @ViewBuilder
    func body(content: Content) -> some View {
        if selected {
            content
                .background { glass }
                .ftGlassSelectionStroke(isSelected: true, shape: shape)
                .scaleEffect(1.03)
        } else {
            content
                .background { glass }
        }
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
        if liquid {
            if interactive, let tint {
                s.fill(.clear).glassEffect(.regular.tint(tint).interactive(), in: s)
            } else if interactive {
                s.fill(.clear).glassEffect(.regular.interactive(), in: s)
            } else if let tint {
                s.fill(.clear).glassEffect(.regular.tint(tint), in: s)
            } else {
                s.fill(.clear).glassEffect(.regular, in: s)
            }
        } else if let tint {
            // Pre-glass styling: a tint becomes a solid fill (buttons/chips);
            // no tint falls back to a frosted material (cards/panels).
            s.fill(tint)
        } else {
            s.fill(.ultraThinMaterial)
        }
    }
}

extension View {
    /// Apply the glass primitive. Default args reproduce the frosted-material
    /// styling; pass `liquid: true` for real Liquid Glass (session controls and
    /// close/back icon buttons only).
    func ftGlass(_ shape: FTGlassShape,
                 interactive: Bool = false,
                 tint: Color? = nil,
                 selected: Bool = false,
                 liquid: Bool = false) -> some View {
        modifier(FTGlassSurface(shape: shape, interactive: interactive, tint: tint, selected: selected, liquid: liquid))
    }

    /// The standard selection rim: bright `brandRail` 2pt when selected,
    /// hairline white-0.08 1pt otherwise. Single definition for every chip/cell.
    @ViewBuilder
    func ftGlassSelectionStroke(isSelected: Bool, shape: FTGlassShape) -> some View {
        let color: Color = isSelected ? FT.Palette.brandRail.opacity(0.85) : FT.Palette.strokeHairline
        let lineWidth: CGFloat = isSelected ? 2 : 1
        switch shape {
        case .capsule:
            overlay(Capsule(style: .continuous).strokeBorder(color, lineWidth: lineWidth))
        case .circle:
            overlay(Circle().strokeBorder(color, lineWidth: lineWidth))
        case .rounded(let r):
            overlay(RoundedRectangle(cornerRadius: r, style: .continuous).strokeBorder(color, lineWidth: lineWidth))
        }
    }
}

/// Thin wrapper over Apple's `GlassEffectContainer` so sibling Liquid Glass
/// elements (e.g. the session pill capsule and its child circles) merge instead
/// of stacking blur. Visual no-op for children without `.glassEffect`.
struct FTGlassContainer<Content: View>: View {
    var spacing: CGFloat? = nil
    @ViewBuilder var content: () -> Content

    var body: some View {
        GlassEffectContainer(spacing: spacing) {
            content()
        }
    }
}

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
                        .foregroundStyle(FT.Palette.textPrimary)
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
                    .strokeBorder(FT.Palette.strokeCard, lineWidth: 1)
            )
        }
        .buttonStyle(FTGlassButtonStyle(shape: .rounded(cornerRadius), haptic: .light, pressedScale: 0.98))
    }
}
