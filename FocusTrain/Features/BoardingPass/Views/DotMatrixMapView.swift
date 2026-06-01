import SwiftUI

/// Procedural dot-matrix world map watermark. Generates continent-like
/// clusters via seeded noise (no bitmap dependency) and renders them as a
/// regular grid of small gray dots inside a `Canvas`.
///
/// Dots are computed once in `init` for a given size hint, then redrawn
/// statically — performant even on iPad Pro.
struct DotMatrixMapView: View {
    var dotSpacing: CGFloat = 4
    var dotSize: CGFloat = 1.6
    var tint: Color = Color(white: 0.42)

    var body: some View {
        Canvas { context, size in
            let dots = Self.computeDots(in: size, spacing: dotSpacing)
            for d in dots {
                let rect = CGRect(
                    x: d.x - dotSize / 2,
                    y: d.y - dotSize / 2,
                    width: dotSize,
                    height: dotSize
                )
                context.fill(Path(ellipseIn: rect), with: .color(tint.opacity(d.alpha)))
            }
        }
        .allowsHitTesting(false)
    }

    private static func computeDots(in size: CGSize, spacing: CGFloat) -> [Dot] {
        guard size.width > 0, size.height > 0 else { return [] }
        var dots: [Dot] = []
        let cols = Int(size.width / spacing)
        let rows = Int(size.height / spacing)
        for r in 0..<rows {
            for c in 0..<cols {
                let nx = CGFloat(c) / CGFloat(max(1, cols - 1))
                let ny = CGFloat(r) / CGFloat(max(1, rows - 1))
                let m = continentMask(nx: nx, ny: ny)
                guard m > 0.42 else { continue }
                let alpha = min(0.9, 0.35 + Double(m - 0.42) * 1.2)
                dots.append(Dot(
                    x: CGFloat(c) * spacing + spacing / 2,
                    y: CGFloat(r) * spacing + spacing / 2,
                    alpha: alpha
                ))
            }
        }
        return dots
    }

    /// Returns ~0...1; higher = "land". Approximates continent-shaped blobs
    /// (americas left, eurasia/africa center-right, oceania bottom-right)
    /// without needing a bitmap.
    private static func continentMask(nx: CGFloat, ny: CGFloat) -> CGFloat {
        // Equator at ny=0.5; squash poles
        let polar = 1 - abs(ny - 0.5) * 1.6
        let blob: (CGFloat, CGFloat, CGFloat, CGFloat) -> CGFloat = { cx, cy, rx, ry in
            let dx = (nx - cx) / rx
            let dy = (ny - cy) / ry
            let d = sqrt(dx * dx + dy * dy)
            return max(0, 1 - d)
        }
        // Rough continent blobs (in 0...1 space):
        let northAmerica = blob(0.18, 0.32, 0.14, 0.18)
        let southAmerica = blob(0.27, 0.68, 0.07, 0.18)
        let europe       = blob(0.50, 0.30, 0.07, 0.10)
        let africa       = blob(0.54, 0.58, 0.10, 0.20)
        let asia         = blob(0.68, 0.32, 0.18, 0.16)
        let oceania      = blob(0.83, 0.72, 0.07, 0.08)
        let raw = max(northAmerica, max(southAmerica, max(europe, max(africa, max(asia, oceania)))))
        // Add noise so coastlines aren't perfect ellipses
        let n = sin(nx * 38) * 0.06 + sin(ny * 41 + 1.7) * 0.06 + sin((nx + ny) * 17) * 0.04
        return min(1, max(0, raw * polar + n))
    }

    private struct Dot {
        let x: CGFloat
        let y: CGFloat
        let alpha: Double
    }
}
