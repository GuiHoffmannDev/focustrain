import SwiftUI

/// Boarding-pass card outline with rounded corners and side notches at the
/// perforation line. Adapted from `TicketShape` in `TrainTicketCard`.
struct BoardingPassShape: Shape {
    var notchY: CGFloat
    var notchRadius: CGFloat = 10
    var cornerRadius: CGFloat = 26

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let r = cornerRadius

        p.move(to: CGPoint(x: r, y: 0))
        p.addLine(to: CGPoint(x: rect.maxX - r, y: 0))
        p.addArc(center: CGPoint(x: rect.maxX - r, y: r),
                 radius: r, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)

        p.addLine(to: CGPoint(x: rect.maxX, y: notchY - notchRadius))
        p.addArc(center: CGPoint(x: rect.maxX, y: notchY),
                 radius: notchRadius, startAngle: .degrees(-90), endAngle: .degrees(90), clockwise: true)

        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - r))
        p.addArc(center: CGPoint(x: rect.maxX - r, y: rect.maxY - r),
                 radius: r, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)

        p.addLine(to: CGPoint(x: r, y: rect.maxY))
        p.addArc(center: CGPoint(x: r, y: rect.maxY - r),
                 radius: r, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)

        p.addLine(to: CGPoint(x: 0, y: notchY + notchRadius))
        p.addArc(center: CGPoint(x: 0, y: notchY),
                 radius: notchRadius, startAngle: .degrees(90), endAngle: .degrees(-90), clockwise: true)

        p.addLine(to: CGPoint(x: 0, y: r))
        p.addArc(center: CGPoint(x: r, y: r),
                 radius: r, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)

        p.closeSubpath()
        return p
    }
}
