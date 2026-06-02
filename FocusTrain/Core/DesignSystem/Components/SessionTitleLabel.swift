import SwiftUI

/// Large outlined white title made to sit over an arbitrary map background.
/// The outline is approximated with eight directional shadowed copies so the
/// text is legible against both dark and bright map regions.
struct SessionTitleLabel: View {
    let text: String

    private static let outlineColor = Color.black.opacity(0.85)
    private static let outlineRadius: CGFloat = 1.5
    private static let outlineOffsets: [(CGFloat, CGFloat)] = [
        (-1.5, 0), (1.5, 0), (0, -1.5), (0, 1.5),
        (-1.0, -1.0), (1.0, -1.0), (-1.0, 1.0), (1.0, 1.0),
    ]

    var body: some View {
        ZStack {
            ForEach(0..<Self.outlineOffsets.count, id: \.self) { i in
                let (dx, dy) = Self.outlineOffsets[i]
                Text(text)
                    .font(.system(size: 28, weight: .bold, design: .default))
                    .foregroundStyle(Self.outlineColor)
                    .offset(x: dx, y: dy)
            }
            Text(text)
                .font(.system(size: 28, weight: .bold, design: .default))
                .foregroundStyle(FT.Palette.white)
        }
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
        .accessibilityAddTraits(.isHeader)
    }
}

#Preview("Single line") {
    ZStack {
        FT.Palette.bgElevated.ignoresSafeArea()
        SessionTitleLabel(text: "Ricardo Flores Magón")
    }
}

#Preview("Wrap") {
    ZStack {
        FT.Palette.bgElevated.ignoresSafeArea()
        SessionTitleLabel(text: "São Paulo Estação da Luz Central")
            .padding(.horizontal, 40)
    }
}
