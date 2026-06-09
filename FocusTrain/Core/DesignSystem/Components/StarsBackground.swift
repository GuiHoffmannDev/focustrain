import SwiftUI
#if os(iOS)
import CoreMotion
#endif

/// A field of ~200 subtly-twinkling stars drawn on a SwiftUI Canvas, with a
/// gentle parallax driven by CoreMotion. Stable across redraws (seeded RNG) so
/// the sky doesn't reshuffle on state changes.
struct StarsBackground: View {
    var count: Int = 200
    var parallaxStrength: CGFloat = 18

    @State private var stars: [Star] = []
    @State private var motion = MotionState()
    #if os(iOS) && canImport(CoreMotion)
    @State private var motionManager: CMMotionManager?
    #endif

    var body: some View {
        Canvas { context, size in
            for star in stars {
                let cx = star.x * size.width + motion.dx * parallaxStrength * star.depth
                let cy = star.y * size.height + motion.dy * parallaxStrength * star.depth
                let rect = CGRect(x: cx - star.radius,
                                  y: cy - star.radius,
                                  width: star.radius * 2,
                                  height: star.radius * 2)
                context.fill(Path(ellipseIn: rect),
                             with: .color(.white.opacity(star.opacity)))
            }
        }
        .ignoresSafeArea()
        .onAppear {
            if stars.isEmpty {
                stars = Star.generate(count: count)
            }
            startMotion()
        }
        .onDisappear { stopMotion() }
    }

    private func startMotion() {
        #if os(iOS) && !os(macOS)
        let mgr = CMMotionManager()
        guard mgr.isDeviceMotionAvailable else { return }
        mgr.deviceMotionUpdateInterval = 1.0 / 30.0
        mgr.startDeviceMotionUpdates(to: .main) { data, _ in
            guard let attitude = data?.attitude else { return }
            let dx = CGFloat(max(-1, min(1, attitude.roll / .pi)))
            let dy = CGFloat(max(-1, min(1, attitude.pitch / .pi)))
            withAnimation(.linear(duration: 1.0 / 30.0)) {
                motion = MotionState(dx: dx, dy: dy)
            }
        }
        motionManager = mgr
        #endif
    }

    private func stopMotion() {
        #if os(iOS) && !os(macOS)
        motionManager?.stopDeviceMotionUpdates()
        motionManager = nil
        #endif
    }

    private struct MotionState { var dx: CGFloat = 0; var dy: CGFloat = 0 }

    fileprivate struct Star {
        let x: CGFloat       // 0...1
        let y: CGFloat       // 0...1
        let radius: CGFloat
        let opacity: Double
        let depth: CGFloat   // 0...1 — bigger = closer = more parallax

        static func generate(count: Int) -> [Star] {
            var rng = SeededRNG(seed: 0xF0C57A1B)
            return (0..<count).map { _ in
                Star(
                    x: CGFloat(rng.unit()),
                    y: CGFloat(rng.unit()),
                    radius: CGFloat(0.4 + rng.unit() * 1.4),
                    opacity: 0.3 + rng.unit() * 0.5,
                    depth: CGFloat(rng.unit())
                )
            }
        }
    }
}

/// Deterministic LCG so the same seed produces the same star field.
private struct SeededRNG {
    var state: UInt64
    init(seed: UInt64) { self.state = seed | 1 }
    mutating func next() -> UInt64 {
        state &*= 6364136223846793005
        state &+= 1442695040888963407
        return state
    }
    mutating func unit() -> Double {
        Double(next() >> 11) / Double(UInt64(1) << 53)
    }
}
