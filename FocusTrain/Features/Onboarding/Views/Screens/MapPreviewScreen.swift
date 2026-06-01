import SwiftUI

struct MapPreviewScreen: View {
    @State private var progress: CGFloat = 0
    @State private var titleIn = false
    @State private var captionIn = false
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 10) {
                GlowText(
                    text: NSLocalizedString("onboarding.map.title", comment: ""),
                    font: FT.Typography.sectionTitle
                )
                .multilineTextAlignment(.center)
                .opacity(titleIn ? 1 : 0)
                .offset(y: titleIn ? 0 : 8)

                Text(NSLocalizedString("onboarding.map.subtitle", comment: ""))
                    .font(FT.Typography.body)
                    .foregroundStyle(FT.Palette.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .opacity(captionIn ? 1 : 0)
            }
            .padding(.top, 8)

            Spacer(minLength: 0)

            mapCard

            Spacer(minLength: 0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { titleIn = true }
            withAnimation(.easeOut(duration: 0.5).delay(0.15)) { captionIn = true }
            withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) {
                progress = 1
            }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }

    private var mapCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(FT.Palette.bgElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(FT.Palette.brandRail.opacity(0.3), lineWidth: 1)
                )

            // Globe tint
            RadialGradient(
                colors: [FT.Palette.success.opacity(0.15), .clear],
                center: .center,
                startRadius: 20,
                endRadius: 220
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

            // Grid lines (lat/long suggestion)
            gridLines

            // Curved route
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                let start = CGPoint(x: w * 0.15, y: h * 0.75)
                let end = CGPoint(x: w * 0.85, y: h * 0.28)
                let control = CGPoint(x: w * 0.5, y: h * 0.05)

                ZStack {
                    // Dashed background path
                    Path { p in
                        p.move(to: start)
                        p.addQuadCurve(to: end, control: control)
                    }
                    .stroke(FT.Palette.textMuted.opacity(0.3),
                            style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [4, 6]))

                    // Animated gold path
                    Path { p in
                        p.move(to: start)
                        p.addQuadCurve(to: end, control: control)
                    }
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            colors: [FT.Palette.success, FT.Palette.brandRail],
                            startPoint: .leading, endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .shadow(color: FT.Palette.brandRail.opacity(0.6), radius: 6)

                    // Origin dot
                    stationDot.position(start)
                    // Destination dot
                    stationDot.position(end)

                    // Moving train
                    let t = progress
                    let trainPos = quadPoint(start: start, control: control, end: end, t: t)
                    Image(systemName: "tram.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(FT.Palette.brandRail)
                        .shadow(color: FT.Palette.brandRail.opacity(0.8), radius: 8)
                        .position(trainPos)
                }
            }
            .padding(20)
        }
        .frame(maxWidth: 340)
        .frame(height: 320)
    }

    private var stationDot: some View {
        ZStack {
            Circle()
                .fill(FT.Palette.brandRail.opacity(pulse ? 0.35 : 0.15))
                .frame(width: 22, height: 22)
            Circle()
                .fill(FT.Palette.brandRail)
                .frame(width: 10, height: 10)
        }
    }

    private var gridLines: some View {
        GeometryReader { geo in
            Path { p in
                let cols = 6
                let rows = 5
                for c in 1..<cols {
                    let x = geo.size.width * CGFloat(c) / CGFloat(cols)
                    p.move(to: CGPoint(x: x, y: 0))
                    p.addLine(to: CGPoint(x: x, y: geo.size.height))
                }
                for r in 1..<rows {
                    let y = geo.size.height * CGFloat(r) / CGFloat(rows)
                    p.move(to: CGPoint(x: 0, y: y))
                    p.addLine(to: CGPoint(x: geo.size.width, y: y))
                }
            }
            .stroke(FT.Palette.textMuted.opacity(0.08), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func quadPoint(start: CGPoint, control: CGPoint, end: CGPoint, t: CGFloat) -> CGPoint {
        let one = 1 - t
        let x = one * one * start.x + 2 * one * t * control.x + t * t * end.x
        let y = one * one * start.y + 2 * one * t * control.y + t * t * end.y
        return CGPoint(x: x, y: y)
    }
}
