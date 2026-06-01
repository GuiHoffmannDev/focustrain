import SwiftUI

struct DestinationCarouselView: View {
    let model: DurationPickerModel

    @State private var scrolledID: String?
    @State private var isSyncing = false

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 12) {
                ForEach(Array(model.destinations.enumerated()), id: \.element.id) { idx, dest in
                    DestinationCard(destination: dest, isSelected: idx == model.selectedIndex)
                        .id(dest.id)
                        .onTapGesture {
                            model.beginInteraction(.carousel)
                            model.select(idx, from: .carousel)
                            model.endInteraction()
                        }
                }
            }
            .scrollTargetLayout()
            .padding(.horizontal, FT.Layout.sideMargin)
        }
        .scrollPosition(id: $scrolledID, anchor: .center)
        .scrollTargetBehavior(.viewAligned)
        .frame(height: 110)
        .onAppear {
            isSyncing = true
            scrolledID = model.selectedDestination.id
        }
        .onChange(of: model.selectedIndex) { _, _ in
            guard model.interactionSource != .carousel else { return }
            isSyncing = true
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                scrolledID = model.selectedDestination.id
            }
        }
        .onChange(of: scrolledID) { _, newID in
            if isSyncing { isSyncing = false; return }   // ignore our own programmatic scroll
            guard let newID, let idx = model.destinations.firstIndex(where: { $0.id == newID }) else { return }
            model.select(idx, from: .carousel)
        }
    }
}

#if DEBUG
#Preview("Carousel") {
    let m = DurationPickerModel(haptics: NoopDetentService())
    return ZStack { FT.Palette.black.ignoresSafeArea(); DestinationCarouselView(model: m) }
}
#endif
