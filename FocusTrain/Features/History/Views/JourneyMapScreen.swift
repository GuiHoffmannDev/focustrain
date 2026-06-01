import SwiftUI
import SwiftData
import MapKit

/// The cumulative "where you've travelled" map: every completed journey's route
/// overlaid on a single world map, fit to show them all, with a tally of how
/// many journeys are drawn. Empty state before any journey exists.
struct JourneyMapScreen: View {
    /// Pop back to History.
    var onBack: () -> Void

    @Query(sort: \Journey.date, order: .reverse) private var journeys: [Journey]

    @State private var appeared = false

    private var routes: [JourneyRoute] {
        journeys.map { j in
            JourneyRoute(
                id: "\(j.code)-\(j.date.timeIntervalSince1970)",
                from: CLLocationCoordinate2D(latitude: j.fromLat, longitude: j.fromLon),
                to: CLLocationCoordinate2D(latitude: j.toLat, longitude: j.toLon)
            )
        }
    }

    var body: some View {
        ZStack {
            FT.Palette.black.ignoresSafeArea()

            if journeys.isEmpty {
                emptyState
                    .opacity(appeared ? 1 : 0)
            } else {
                JourneyMapView(routes: routes)
                    .ignoresSafeArea()
                    .opacity(appeared ? 1 : 0)

                // Top gradient scrim so the header reads over the map.
                LinearGradient(
                    colors: [FT.Palette.black.opacity(0.85), .clear],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 220)
                .frame(maxHeight: .infinity, alignment: .top)
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }

            VStack {
                header
                    .padding(.horizontal, FT.Layout.sideMargin)
                    .padding(.top, 8)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : -12)
                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            guard !appeared else { return }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                appeared = true
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(FT.Palette.white)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(FT.Palette.bgElevated.opacity(0.6)))
            }
            .buttonStyle(.plain)

            Spacer()

            VStack(spacing: 2) {
                Text(NSLocalizedString("journeymap.title", comment: ""))
                    .font(FT.Typography.sectionTitle)
                    .foregroundStyle(FT.Palette.white)
                if !journeys.isEmpty {
                    Text("\(journeys.count) \(NSLocalizedString("journeymap.count", comment: ""))")
                        .font(FT.Typography.caption)
                        .foregroundStyle(FT.Palette.textSecondary)
                        .contentTransition(.numericText())
                }
            }

            Spacer()

            // Balance the back button so the title stays centred.
            Color.clear.frame(width: 40, height: 40)
        }
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "map.fill")
                .font(.system(size: 52))
                .foregroundStyle(FT.Palette.textMuted)
            Text(NSLocalizedString("journeymap.empty", comment: ""))
                .font(FT.Typography.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(FT.Palette.textSecondary)
        }
        .padding(.horizontal, FT.Layout.sideMargin)
    }
}
