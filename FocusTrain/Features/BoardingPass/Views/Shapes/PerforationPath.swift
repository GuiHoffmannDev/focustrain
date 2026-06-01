import SwiftUI

/// Horizontal dashed line at the perforation height. Stateless decoration —
/// the actual tear is rendered by `TornEdgePath` over the top half's mask.
struct PerforationPath: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let y = rect.midY
        p.move(to: CGPoint(x: 4, y: y))
        p.addLine(to: CGPoint(x: rect.maxX - 4, y: y))
        return p
    }
}
