import SwiftUI

/// Small uppercase muted label above a large white value.
/// Used in the bottom corners of `SessionView` for time and distance.
struct SessionMetricTile: View {
    let label: String
    let value: String
    var alignment: HorizontalAlignment = .leading
    /// `false` over a light map (mono/standard in light), where the value needs
    /// dark text instead of white.
    var onDarkBackdrop: Bool = true

    var body: some View {
        VStack(alignment: alignment, spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .semibold, design: .default))
                .tracking(0.6)
                .textCase(.uppercase)
                .foregroundStyle(FT.Palette.textMuted)

            Text(value)
                .font(.system(size: 28, weight: .bold, design: .default))
                .foregroundStyle(onDarkBackdrop ? FT.Palette.white : FT.Palette.textPrimary)
                .shadow(color: FT.Palette.shadowSoft, radius: 3, x: 0, y: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label), \(value)")
    }
}

#Preview {
    HStack {
        SessionMetricTile(label: "Time Remaining", value: "259 min", alignment: .leading)
        Spacer()
        SessionMetricTile(label: "Distance Remaining", value: "3.268 km", alignment: .trailing)
    }
    .padding()
    .background(FT.Palette.bgElevated)
}
