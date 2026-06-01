import SwiftUI

/// Mask shape that exposes the upper or lower half of the boarding pass
/// along a ragged, seeded boundary line.
///
/// The boundary follows the perforation Y until `progress * width`, then
/// jags with a deterministic noise (mix of sines seeded by `seed`). Past
/// that point the line returns to the flat perforation — the right edge
/// is still "uncut".
struct TornEdgePath: Shape {
    enum Side { case upper, lower }

    var progress: CGFloat
    var perforationY: CGFloat
    var amplitude: CGFloat
    var seed: UInt32
    var side: Side

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let segments = 48
        let w = rect.width
        let cutEnd = max(0, min(w, w * progress))
        let step = w / CGFloat(segments)

        var pts: [CGPoint] = []
        pts.reserveCapacity(segments + 1)
        for i in 0...segments {
            let x = CGFloat(i) * step
            let y: CGFloat
            if x <= cutEnd {
                y = perforationY + Self.noise(x: x, seed: seed) * amplitude
            } else {
                y = perforationY
            }
            pts.append(CGPoint(x: x, y: y))
        }

        switch side {
        case .upper:
            p.move(to: CGPoint(x: 0, y: 0))
            p.addLine(to: pts[0])
            for pt in pts.dropFirst() { p.addLine(to: pt) }
            p.addLine(to: CGPoint(x: rect.maxX, y: 0))
            p.closeSubpath()
        case .lower:
            p.move(to: CGPoint(x: 0, y: rect.maxY))
            p.addLine(to: pts[0])
            for pt in pts.dropFirst() { p.addLine(to: pt) }
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            p.closeSubpath()
        }
        return p
    }

    static func noise(x: CGFloat, seed: UInt32) -> CGFloat {
        let s = CGFloat(seed % 1000) * 0.01
        let a = sin(x * 0.13 + s) * 0.55
        let b = sin(x * 0.41 + s * 1.7) * 0.30
        let c = sin(x * 0.07 + s * 0.3 + 1.1) * 0.20
        return a + b + c
    }
}
