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
