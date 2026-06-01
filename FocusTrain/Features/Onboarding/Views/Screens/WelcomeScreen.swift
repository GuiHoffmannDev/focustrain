import SwiftUI

struct WelcomeScreen: View {
    @State private var phase: Int = 0
    @State private var trainOffset: CGFloat = -260
    @State private var trackPhase: CGFloat = 0
    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var starsOpacity: Double = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                StarField()
                    .opacity(starsOpacity)
                    .frame(height: 220)

                VStack(spacing: 28) {
                    trainEmblem
                        .offset(x: trainOffset)
                    Tracks(phase: trackPhase)
                        .stroke(
                            LinearGradient(
                                colors: [.clear, FT.Palette.brandRail.opacity(0.8), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [6, 8])
                        )
                        .frame(height: 2)
                        .padding(.horizontal, 24)
                }
            }
            .frame(maxWidth: .infinity)

            Spacer()

            VStack(spacing: 14) {
                GlowText(text: NSLocalizedString("onboarding.welcome.title", comment: ""))
                    .multilineTextAlignment(.center)
                    .opacity(titleOpacity)
                    .offset(y: titleOpacity == 0 ? 12 : 0)

                Text(NSLocalizedString("onboarding.welcome.subtitle", comment: ""))
                    .font(FT.Typography.body)
                    .foregroundStyle(FT.Palette.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .opacity(subtitleOpacity)
                    .offset(y: subtitleOpacity == 0 ? 8 : 0)
            }

            Spacer()
        }
        .onAppear(perform: runIntro)
    }

    private var trainEmblem: some View {
        ZStack {
            Circle()
                .fill(FT.Palette.brandRail.opacity(0.18))
                .frame(width: 140, height: 140)
                .blur(radius: 14)
            Circle()
                .fill(FT.Palette.bgElevated)
                .frame(width: 96, height: 96)
                .overlay(
                    Circle().stroke(FT.Palette.brandRail.opacity(0.6), lineWidth: 1)
                )
            Image(systemName: "tram.fill")
                .font(.system(size: 44, weight: .regular))
                .foregroundStyle(FT.Palette.brandRail)
                .shadow(color: FT.Palette.brandRail.opacity(0.7), radius: 12)
        }
    }

    private func runIntro() {
        withAnimation(.easeOut(duration: 0.9)) { starsOpacity = 1 }
        withAnimation(.spring(response: 1.1, dampingFraction: 0.72).delay(0.15)) {
            trainOffset = 0
        }
        withAnimation(.linear(duration: 2.4).repeatForever(autoreverses: false).delay(0.2)) {
            trackPhase = 1
        }
        withAnimation(.easeOut(duration: 0.6).delay(0.85)) { titleOpacity = 1 }
        withAnimation(.easeOut(duration: 0.6).delay(1.15)) { subtitleOpacity = 1 }
    }
}

private struct Tracks: Shape {
    var phase: CGFloat
    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return p
    }
}

private struct StarField: View {
    private let points: [(CGFloat, CGFloat, CGFloat)] = (0..<28).map { i in
        let x = CGFloat((i * 37) % 100) / 100
        let y = CGFloat((i * 53) % 100) / 100
        let s = CGFloat((i * 13) % 5 + 1)
        return (x, y, s)
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.05)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                for (i, p) in points.enumerated() {
                    let phase = (sin(t * 0.8 + Double(i)) + 1) / 2
                    let alpha = 0.15 + phase * 0.5
                    let rect = CGRect(
                        x: p.0 * size.width,
                        y: p.1 * size.height,
                        width: p.2, height: p.2
                    )
                    ctx.fill(Path(ellipseIn: rect), with: .color(.white.opacity(alpha)))
                }
            }
        }
    }
}
