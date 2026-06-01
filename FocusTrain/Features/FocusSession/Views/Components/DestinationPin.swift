import SwiftUI

struct DestinationPin: View {
    let destination: Destination
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: "airplane")
                .font(.system(size: 9, weight: .bold))
                .rotationEffect(.degrees(-45))
            Text(destination.code)
                .font(.system(size: 10, weight: .heavy))
        }
        .foregroundStyle(isSelected ? FT.Palette.ink : FT.Palette.white)
        .padding(.horizontal, 7).padding(.vertical, 5)
        .background(
            Capsule().fill(isSelected ? FT.Palette.brandRail : FT.Palette.bgElevated.opacity(0.7))
        )
        .overlay(
            Capsule().stroke(isSelected ? Color.clear : FT.Palette.textMuted.opacity(0.35), lineWidth: 1)
        )
        .scaleEffect(isSelected ? 1.12 : 1.0)
        .accessibilityElement()
        .accessibilityLabel(Text("\(destination.city), \(destination.minutes) " + NSLocalizedString("durationPicker.minutes", comment: "")))
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }
}
