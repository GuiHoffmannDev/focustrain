import SwiftUI

/// A one-shot celebratory burst of gold/white particles, drawn with
/// `TimelineView` + `Canvas` so it animates without per-particle SwiftUI views.
/// Particles launch upward from the lower-centre, spread, and fall under gravity
/// while fading — matching the arrival celebration's gold/white palette.
struct ConfettiCanvas: View {
    /// Number of particles in the burst.
    var count: Int = 90
    /// Seconds for the burst to fully play out and fade.
    var duration: Double = 2.6

    private let particles: [Particle]
    private let start = Date()

    init(count: Int = 90, duration: Double = 2.6) {
        self.count = count
        self.duration = duration
        var rng = SystemRandomNumberGenerator()
        self.particles = (0..<count).map { _ in Particle(rng: &rng) }
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSince(start)
                guard t < duration else { return }

                for p in particles {
                    draw(p, at: t, in: &context, size: size)
                }
            }
            .allowsHitTesting(false)
        }
    }

    private func draw(_ p: Particle, at t: Double, in context: inout GraphicsContext, size: CGSize) {
        let delay = p.delay
        guard t >= delay else { return }
        let lt = t - delay                       // local time since this particle launched
        let life = duration - delay
        let progress = min(1, lt / life)

        // Launch from just below centre; integrate simple projectile + gravity.
        let originX = size.width * 0.5
        let originY = size.height * 0.66
        let gravity = 900.0
        let x = originX + p.vx * lt
        let y = originY + p.vy * lt + 0.5 * gravity * lt * lt

        guard y < size.height + 40 else { return }

        let fade = 1 - pow(progress, 2.2)
        let opacity = max(0, fade)
        let angle = p.spin * lt
        let s = p.size

        var ctx = context
        ctx.translateBy(x: x, y: y)
        ctx.rotate(by: .radians(angle))
        ctx.opacity = opacity

        let rect = CGRect(x: -s / 2, y: -s / 2, width: s, height: s * 0.6)
        ctx.fill(Path(roundedRect: rect, cornerRadius: 1.5), with: .color(p.color))
    }

    private struct Particle {
        let vx: Double
        let vy: Double
        let size: Double
        let spin: Double
        let delay: Double
        let color: Color

        init(rng: inout SystemRandomNumberGenerator) {
            // Upward fan: negative vy, spread horizontally.
            vx = Double.random(in: -260...260, using: &rng)
            vy = Double.random(in: -780 ... -420, using: &rng)
            size = Double.random(in: 6...12, using: &rng)
            spin = Double.random(in: -6...6, using: &rng)
            delay = Double.random(in: 0...0.35, using: &rng)
            color = Particle.palette.randomElement(using: &rng)!
        }

        static let palette: [Color] = [
            FT.Palette.brandBrass,
            FT.Palette.white,
            FT.Palette.brandBrass.opacity(0.85),
            FT.Palette.brandRail,
            FT.Palette.success
        ]
    }
}
