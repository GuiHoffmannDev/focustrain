import SwiftUI

struct DestinationCard: View {
    let destination: Destination
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(destination.code)
                .font(.system(size: 20, weight: .heavy))
            Text(destination.city)
                .font(.system(size: 13, weight: .medium))
                .lineLimit(1).minimumScaleFactor(0.7)
            HStack(spacing: 6) {
                Text("\(destination.minutes)m").font(.system(size: 15, weight: .bold))
                Text("·").opacity(0.5)
                Text("~\(destination.nominalKm)km").font(.system(size: 12, weight: .medium)).opacity(0.7)
            }
        }
        .foregroundStyle(isSelected ? FT.Palette.ink : FT.Palette.white)
        .frame(width: 140, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(isSelected ? FT.Palette.brandRail : FT.Palette.bgElevated.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(isSelected ? Color.clear : FT.Palette.textMuted.opacity(0.25), lineWidth: 1)
        )
        .scaleEffect(isSelected ? 1.03 : 1.0)
    }
}
