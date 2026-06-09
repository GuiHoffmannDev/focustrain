import SwiftUI

/// Horizontal strip of destination cards shown below the time ruler. Acts as a
/// third selection surface alongside the ruler and the map: tapping a card
/// selects that destination; changes from any source recenter the strip on the
/// selected card.
struct DestinationCardStripView: View {
    let model: DurationPickerModel

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: FT.Layout.spacing) {
                    ForEach(model.destinations.indices, id: \.self) { idx in
                        let destination = model.destinations[idx]
                        DestinationCard(
                            destination: destination,
                            isSelected: idx == model.selectedIndex,
                            onTap: {
                                model.beginInteraction(.ruler)
                                model.select(idx, from: .ruler)
                                model.endInteraction()
                            }
                        )
                        .id(destination.id)
                    }
                }
                .padding(.horizontal, FT.Layout.sideMargin)
            }
            .onAppear {
                if let id = model.selectedDestination?.id {
                    proxy.scrollTo(id, anchor: .center)
                }
            }
            .onChange(of: model.selectedIndex) { _, _ in
                guard let id = model.selectedDestination?.id else { return }
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    proxy.scrollTo(id, anchor: .center)
                }
            }
        }
        .frame(height: 104)
    }
}

private struct DestinationCard: View {
    let destination: Destination
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "tram.fill")
                        .font(.system(size: 13, weight: .bold))
                    Text(destination.code)
                        .font(FT.Typography.badge)
                }
                .foregroundStyle(isSelected ? FT.Palette.black : FT.Palette.brandBrass)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isSelected ? FT.Palette.brandBrass : FT.Palette.black)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(isSelected ? FT.Palette.black : FT.Palette.brandBrass,
                                lineWidth: 1.5)
                )

                Text(destination.city)
                    .font(FT.Typography.body)
                    .foregroundStyle(isSelected ? FT.Palette.black : FT.Palette.white)
                    .lineLimit(1)

                Text(destination.durationLabel)
                    .font(FT.Typography.caption)
                    .foregroundStyle(FT.Palette.textSecondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .frame(width: 132, height: 96, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(isSelected ? FT.Palette.white : FT.Palette.black)
            )
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(destination.city), \(destination.code), \(destination.minutes) minutes")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

#if DEBUG
#Preview("DestinationCardStripView") {
    let m = DurationPickerModel(haptics: NoopDetentService())
    return ZStack {
        FT.Palette.black.ignoresSafeArea()
        VStack {
            Spacer()
            DestinationCardStripView(model: m)
            Spacer().frame(height: 80)
        }
    }
}
#endif
