import SwiftUI

struct ReadyScreen: View {
    @State private var emblemIn = false
    @State private var titleIn = false
    @State private var captionIn = false
    @State private var sparkle = false
    @State private var ringRotate: Double = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            ZStack {
                // Outer rotating ring
                Circle()
                    .trim(from: 0, to: 0.85)
                    .stroke(
                        AngularGradient(
                            colors: [FT.Palette.brandRail, FT.Palette.success, FT.Palette.brandRail.opacity(0.2), FT.Palette.brandRail],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 220, height: 220)
                    .rotationEffect(.degrees(ringRotate))
                    .shadow(color: FT.Palette.brandRail.opacity(0.5), radius: 14)

                // Glow halo
                Circle()
                    .fill(FT.Palette.brandRail.opacity(sparkle ? 0.25 : 0.10))
                    .frame(width: 200, height: 200)
                    .blur(radius: 30)

                // Emblem
                ZStack {
                    Circle()
                        .fill(FT.Palette.bgElevated)
                        .frame(width: 150, height: 150)
                        .overlay(Circle().stroke(FT.Palette.brandRail, lineWidth: 2))
                    Image(systemName: "tram.fill")
                        .font(.system(size: 60, weight: .regular))
                        .foregroundStyle(FT.Palette.brandRail)
                        .shadow(color: FT.Palette.brandRail.opacity(0.6), radius: 12)
                }
                .scaleEffect(emblemIn ? 1 : 0.5)
                .opacity(emblemIn ? 1 : 0)

                // Floating sparkles
                ForEach(0..<6, id: \.self) { i in
                    let angle = Double(i) * 60.0
                    Image(systemName: "sparkle")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(FT.Palette.brandRail)
                        .offset(y: -130)
                        .rotationEffect(.degrees(angle + (sparkle ? 14 : -14)))
                        .opacity(sparkle ? 0.9 : 0.3)
                }
            }
            .frame(height: 280)

            Spacer(minLength: 24)

            VStack(spacing: 14) {
                GlowText(
                    text: NSLocalizedString("onboarding.ready.title", comment: ""),
                    font: FT.Typography.heroTitle
                )
                .multilineTextAlignment(.center)
                .opacity(titleIn ? 1 : 0)
                .offset(y: titleIn ? 0 : 10)

                Text(NSLocalizedString("onboarding.ready.subtitle", comment: ""))
                    .font(FT.Typography.body)
                    .foregroundStyle(FT.Palette.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .opacity(captionIn ? 1 : 0)
            }

            Spacer(minLength: 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                emblemIn = true
            }
            withAnimation(.linear(duration: 14).repeatForever(autoreverses: false)) {
                ringRotate = 360
            }
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                sparkle = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.4)) { titleIn = true }
            withAnimation(.easeOut(duration: 0.5).delay(0.6)) { captionIn = true }
        }
    }
}
