import SwiftUI
import SwiftData
import CoreLocation

/// The cinematic Home: stars + a MapKit globe centred on the user's city, a
/// pulsing white pin (with the streak badge floating beside it when active),
/// a greeting + giant city name + Premium offer pill on top, and a primary CTA
/// + three glass action cards (History / Trends / Settings) on the bottom.
struct HomeView: View {
    var onStart: () -> Void
    var onHistory: () -> Void
    var onTrends: () -> Void = {}
    var onSettings: () -> Void = {}

    @Query(sort: \Journey.date, order: .reverse) private var journeys: [Journey]

    @State private var resolver = CurrentCityResolver()
    @State private var appeared = false

    // Centre of the world if the user denies location: a soft default that
    // still looks pretty (mid-Atlantic) and never resolves to "weird".
    private static let fallbackCenter = CLLocationCoordinate2D(latitude: 20, longitude: 0)

    private var streak: Int {
        StreakCalculator.currentStreak(from: journeys)
    }

    private var routes: [JourneyRoute] {
        journeys.map {
            JourneyRoute(
                id: $0.code,
                from: CLLocationCoordinate2D(latitude: $0.fromLat, longitude: $0.fromLon),
                to: CLLocationCoordinate2D(latitude: $0.toLat, longitude: $0.toLon)
            )
        }
    }

    private var cityDisplay: String {
        if let city = resolver.cityName, !city.isEmpty { return city }
        return NSLocalizedString("home.greeting.fallbackName", comment: "")
    }

    private var globeCenter: CLLocationCoordinate2D {
        resolver.coordinate ?? Self.fallbackCenter
    }

    var body: some View {
        ZStack {
            FT.Palette.black.ignoresSafeArea()

            GlobeHomeView(center: globeCenter, routes: routes)
                .ignoresSafeArea()
                .opacity(0.85)

            StarsBackground()
                .blendMode(.screen)
                .allowsHitTesting(false)

            // Top vignette so greeting + pill stay readable over the globe.
            LinearGradient(
                colors: [FT.Palette.black.opacity(0.65), .clear],
                startPoint: .top, endPoint: .center
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            // Bottom vignette behind the CTA stack.
            LinearGradient(
                colors: [.clear, FT.Palette.black.opacity(0.85)],
                startPoint: .center, endPoint: .bottom
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            PulsingPin(streak: streak)
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                topBlock
                    .padding(.horizontal, FT.Layout.sideMargin)
                    .padding(.top, 8)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : -12)

                Spacer(minLength: 0)

                bottomBlock
                    .padding(.horizontal, FT.Layout.sideMargin)
                    .padding(.bottom, 16)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 24)
            }
        }
        .onAppear {
            resolver.bootstrap()
            guard !appeared else { return }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.9)) {
                appeared = true
            }
        }
    }

    // MARK: - Top

    private var topBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(NSLocalizedString(GreetingPeriod.key(), comment: ""))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(FT.Palette.textSecondary)

                    Text(cityDisplay)
                        .font(.system(size: 44, weight: .heavy))
                        .foregroundStyle(FT.Palette.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .contentTransition(.opacity)
                        .animation(.spring(response: 0.6, dampingFraction: 0.9),
                                   value: cityDisplay)
                }

                Spacer()

                PremiumDiscountPill()
            }
        }
    }

    // MARK: - Bottom

    private var bottomBlock: some View {
        VStack(spacing: 14) {
            CTAButton(
                title: NSLocalizedString("home.cta.start", comment: ""),
                style: .primary,
                icon: "arrow.right",
                action: onStart
            )

            VStack(spacing: 10) {
                SheetActionCard(
                    title: NSLocalizedString("home.card.history", comment: ""),
                    caption: NSLocalizedString("home.card.history.caption", comment: ""),
                    systemImage: "clock.arrow.circlepath",
                    action: onHistory
                )
                SheetActionCard(
                    title: NSLocalizedString("home.card.trends", comment: ""),
                    caption: NSLocalizedString("home.card.trends.caption", comment: ""),
                    systemImage: "chart.bar.xaxis",
                    action: onTrends
                )
                SheetActionCard(
                    title: NSLocalizedString("home.card.settings", comment: ""),
                    caption: NSLocalizedString("home.card.settings.caption", comment: ""),
                    systemImage: "gearshape.fill",
                    action: onSettings
                )
            }
        }
    }
}
