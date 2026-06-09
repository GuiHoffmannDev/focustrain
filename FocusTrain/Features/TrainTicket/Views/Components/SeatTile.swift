import SwiftUI
import UIKit

/// Single seat in the wagon grid. Three visual states share the same footprint
/// so the layout never reflows when selection changes.
struct SeatTile: View {
    enum State {
        case available
        case previouslyUsed   // user has occupied this seat in a past journey
        case selected
    }

    let code: String
    let state: State
    let onTap: () -> Void

    var body: some View {
        Button(action: handleTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.clear)
                    .ftGlassRounded(cornerRadius: 10, interactive: true, tint: glassTint)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(strokeColor, lineWidth: strokeWidth)
                    )

                Text(label)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(textColor)
            }
            .frame(width: 38, height: 38)
            .scaleEffect(state == .selected ? 1.06 : 1.0)
            .shadow(
                color: state == .selected ? FT.Palette.brandRail.opacity(0.35) : .clear,
                radius: 8,
                y: 2
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(code))
        .accessibilityAddTraits(state == .selected ? .isSelected : [])
    }

    private func handleTap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        onTap()
    }

    private var glassTint: Color? {
        switch state {
        case .available:      return nil
        case .previouslyUsed: return FT.Palette.brandRail.opacity(0.18)
        case .selected:       return FT.Palette.brandRail
        }
    }

    private var strokeColor: Color {
        switch state {
        case .available:      return FT.Palette.textMuted.opacity(0.3)
        case .previouslyUsed: return FT.Palette.brandRail.opacity(0.45)
        case .selected:       return .clear
        }
    }

    private var strokeWidth: CGFloat {
        state == .previouslyUsed ? 1 : 1
    }

    private var textColor: Color {
        switch state {
        case .available:      return FT.Palette.textMuted
        case .previouslyUsed: return FT.Palette.white.opacity(0.75)
        case .selected:       return FT.Palette.ink
        }
    }

    private var label: String {
        // Show only the column letter — the row number is rendered alongside
        // the row in `WagonView`, so the tile stays uncluttered.
        String(code.suffix(1))
    }
}
