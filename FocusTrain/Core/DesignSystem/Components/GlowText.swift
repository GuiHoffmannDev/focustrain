import SwiftUI

struct GlowText: View {
    let text: String
    var font: Font = FT.Typography.heroTitle

    @State private var pulse: CGFloat = 0.45

    var body: some View {
        Text(text)
            .font(font)
            .foregroundStyle(
                LinearGradient(
                    colors: [FT.Palette.brandRail, FT.Palette.white, FT.Palette.brandRail],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .shadow(color: FT.Palette.brandRail.opacity(pulse), radius: 18, x: 0, y: 0)
            .shadow(color: FT.Palette.brandRail.opacity(pulse * 0.5), radius: 36, x: 0, y: 0)
            .onAppear {
                withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                    pulse = 0.7
                }
            }
    }
}
