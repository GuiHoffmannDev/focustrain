import SwiftUI

/// Full-screen streaks that sell the departure run: thin vertical lines rushing
/// downward while the train translates up. Stateless — driven by the timeline
/// clock; `progress` (0...1 over the run) ramps density and speed in.
struct SpeedLinesOverlay: View {
    let progress: Double

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let lineCount = 16
                for i in 0..<lineCount {
                    let seed = Double((i &* 2654435761) % 1000) / 1000.0
                    let x = CGFloat(seed) * size.width
                    let speed = 900.0 + seed * 900.0
                    let length = CGFloat(60 + seed * 140) * CGFloat(0.5 + progress)
                    let cycle = Double(size.height) + Double(length) * 2
                    let travelled = (t * speed * (0.3 + progress)).truncatingRemainder(dividingBy: cycle)
                    let y = CGFloat(travelled) - length
                    let alpha = (0.05 + 0.22 * progress) * (0.4 + seed * 0.6)
                    var path = Path()
                    path.move(to: CGPoint(x: x, y: y))
                    path.addLine(to: CGPoint(x: x, y: y + length))
                    // Adaptive so streaks read in both schemes: light on the
                    // dark train, dark on the light background.
                    context.stroke(path, with: .color(FT.Palette.textPrimary.opacity(alpha)), lineWidth: 1.5)
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

#Preview {
    ZStack {
        FT.Palette.black.ignoresSafeArea()
        SpeedLinesOverlay(progress: 1)
    }
}
