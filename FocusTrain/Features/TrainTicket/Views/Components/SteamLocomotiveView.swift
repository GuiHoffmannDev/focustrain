import SwiftUI

/// Top-down steam locomotive that crowns the train composition: rounded
/// smokebox nose, chimney with a brass ring, steam dome, long boiler with
/// transverse bands, and the driver's cab at the rear. Pure chrome — no
/// interaction. Steam puffs rise from the chimney into the sky headroom;
/// `steamIntensity` ramps them up during the departure run.
struct SteamLocomotiveView: View {
    var steamIntensity: Double = 0.35   // 0...1

    static let height: CGFloat = 320

    private let skyHeadroom: CGFloat = 96
    private let cabHeight: CGFloat = 84
    private let boilerWidthRatio: CGFloat = 0.58
    private let cabWidthRatio: CGFloat = 0.86

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let bodyTop = skyHeadroom
            let boilerHeight = Self.height - skyHeadroom - cabHeight + 14
            let boilerWidth = w * boilerWidthRatio
            let cabWidth = w * cabWidthRatio
            let chimneyCenter = CGPoint(x: w / 2, y: bodyTop + 34)

            ZStack {
                // Boiler with rounded smokebox nose.
                BoilerShape()
                    .fill(FT.Palette.bgElevated.opacity(0.25))
                    .overlay(
                        BoilerShape().stroke(FT.Palette.textMuted.opacity(0.35), lineWidth: 1.5)
                    )
                    .frame(width: boilerWidth, height: boilerHeight)
                    .position(x: w / 2, y: bodyTop + boilerHeight / 2)

                // Transverse boiler bands.
                ForEach(0..<3, id: \.self) { i in
                    Rectangle()
                        .fill(FT.Palette.textMuted.opacity(0.3))
                        .frame(width: boilerWidth, height: 1)
                        .position(x: w / 2, y: bodyTop + boilerHeight * (0.45 + 0.17 * CGFloat(i)))
                }

                // Driver's cab.
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(FT.Palette.bgElevated.opacity(0.35))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(FT.Palette.textMuted.opacity(0.35), lineWidth: 1.5)
                    )
                    .frame(width: cabWidth, height: cabHeight)
                    .position(x: w / 2, y: Self.height - cabHeight / 2)

                // Cab roof hatch.
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(FT.Palette.textMuted.opacity(0.3), lineWidth: 1)
                    .frame(width: 46, height: 18)
                    .position(x: w / 2, y: Self.height - cabHeight / 2)

                // Steam dome (brass).
                Circle()
                    .fill(FT.Palette.brandBrass.opacity(0.18))
                    .overlay(Circle().stroke(FT.Palette.brandBrass.opacity(0.5), lineWidth: 1.5))
                    .frame(width: 22, height: 22)
                    .position(x: w / 2, y: bodyTop + boilerHeight * 0.58)

                // Chimney with brass ring, near the nose.
                Circle()
                    .fill(FT.Palette.bgElevated)
                    .overlay(Circle().stroke(FT.Palette.brandBrass, lineWidth: 2))
                    .frame(width: 30, height: 30)
                    .position(chimneyCenter)

                SteamPuffsView(intensity: steamIntensity, emitter: chimneyCenter)
            }
        }
        .frame(height: Self.height)
        .allowsHitTesting(false)
    }
}

/// Long rounded rectangle whose top edge is a semicircle — the smokebox nose.
private struct BoilerShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let r = rect.width / 2
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
        p.addArc(
            center: CGPoint(x: rect.midX, y: rect.minY + r),
            radius: r,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

/// Stateless steam puffs: each puff loops on its own period, rising and fading
/// above the emitter. Driven purely by the timeline clock — no @State.
private struct SteamPuffsView: View {
    let intensity: Double
    let emitter: CGPoint

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            Canvas { context, _ in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let count = 5
                for i in 0..<count {
                    let phaseOffset = Double(i) / Double(count)
                    let period = 2.6 - 1.4 * intensity
                    let progress = ((t / period) + phaseOffset).truncatingRemainder(dividingBy: 1)
                    let rise = 60.0 + 40.0 * intensity
                    let drift = sin((t + Double(i) * 7) * 0.8) * 6
                    let x = emitter.x + CGFloat(drift)
                    let y = emitter.y - 18 - CGFloat(progress * rise)
                    let radius = CGFloat(6 + progress * 14)
                    let alpha = (1 - progress) * (0.08 + 0.22 * intensity)
                    let rect = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
                    context.fill(Ellipse().path(in: rect), with: .color(FT.Palette.white.opacity(alpha)))
                }
            }
        }
        .allowsHitTesting(false)
    }
}

/// Small coupling drawn between the locomotive and the carriage.
struct TrainCouplingView: View {
    var body: some View {
        VStack(spacing: 3) {
            Capsule()
                .fill(FT.Palette.textMuted.opacity(0.45))
                .frame(width: 6, height: 14)
            Capsule()
                .fill(FT.Palette.textMuted.opacity(0.3))
                .frame(width: 14, height: 3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 2)
    }
}

#Preview {
    ZStack {
        FT.Palette.black.ignoresSafeArea()
        VStack(spacing: 0) {
            SteamLocomotiveView(steamIntensity: 0.35)
            TrainCouplingView()
        }
        .padding(.horizontal, 24)
    }
}
