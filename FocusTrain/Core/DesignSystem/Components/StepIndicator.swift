import SwiftUI

struct StepIndicator: View {
    let segments: Int
    let activeSegment: Int

    init(segments: Int = FT.Layout.stepSegments, activeSegment: Int) {
        self.segments = segments
        self.activeSegment = activeSegment
    }

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<segments, id: \.self) { idx in
                Capsule()
                    .fill(idx <= activeSegment
                          ? FT.Palette.brandRail
                          : FT.Palette.textMuted.opacity(0.3))
                    .frame(width: FT.Layout.stepBarWidth, height: FT.Layout.stepBarHeight)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: activeSegment)
            }
        }
    }
}
