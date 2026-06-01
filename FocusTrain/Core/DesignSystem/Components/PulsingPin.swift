import SwiftUI

/// The cinematic pin used at the center of the Home globe: a white dot with a
/// soft pulsing ring around it. Optionally hosts a streak badge (🔥 + count)
/// floating to its right.
struct PulsingPin: View {
    var streak: Int = 0

    @State private var animating = false

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(FT.Palette.brandRail.opacity(0.45), lineWidth: 2)
                    .frame(width: 56, height: 56)
                    .scaleEffect(animating ? 1.15 : 1.0)
                    .opacity(animating ? 0 : 0.9)

                Circle()
                    .stroke(FT.Palette.brandRail.opacity(0.25), lineWidth: 1)
                    .frame(width: 40, height: 40)
                    .scaleEffect(animating ? 1.10 : 1.0)
                    .opacity(animating ? 0.2 : 0.7)

                Circle()
                    .fill(FT.Palette.brandRail)
                    .frame(width: 14, height: 14)
                    .shadow(color: FT.Palette.brandRail.opacity(0.6),
                            radius: 8, x: 0, y: 0)
            }
            .frame(width: 60, height: 60)

            if streak > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(FT.Palette.brandBrass)
                    Text("\(streak)")
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundStyle(FT.Palette.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(.ultraThinMaterial)
                )
                .overlay(
                    Capsule().stroke(FT.Palette.brandBrass.opacity(0.4), lineWidth: 1)
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: false)) {
                animating = true
            }
        }
    }
}
