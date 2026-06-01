import SwiftUI

struct StationBadge: View {
    enum Variant { case rail, brass }

    let code: String
    var variant: Variant = .rail

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "tram.fill")
                .font(.system(size: 12, weight: .bold))
            Text(code)
                .font(FT.Typography.badge)
                .tracking(0.5)
        }
        .foregroundStyle(foreground)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(background)
        .clipShape(Capsule())
    }

    private var background: Color {
        switch variant {
        case .rail:  return FT.Palette.brandRail
        case .brass: return FT.Palette.brandBrass
        }
    }

    private var foreground: Color {
        switch variant {
        case .rail:  return FT.Palette.white
        case .brass: return FT.Palette.ink
        }
    }
}
