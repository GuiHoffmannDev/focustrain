import SwiftUI
import Observation
import CoreLocation

/// Single source of truth for the destination/duration picker. The destination
/// ladder is built from cities within a radius of the origin, queried on demand
/// (see `CityDatabase.nearby` + `Destination.makeLadder`); the selected
/// `Destination` drives both the focus duration and the route.
@MainActor
@Observable
final class DurationPickerModel {
    enum InteractionSource: Equatable { case none, ruler, map }

    private(set) var destinations: [Destination] = []
    private(set) var origin: Station
    private(set) var selectedIndex: Int = 0
    var interactionSource: InteractionSource = .none

    var scenario: FocusScenario
    var mapStyle: MapStyle
    var mapShowLabels: Bool

    private let haptics: DetentHapticsService
    private let database: CityDatabase
    private let homeCityStore: HomeCityStore
    private var loaderTask: Task<Void, Never>?

    /// Radius (km) for the candidate query. The farthest ladder slot (150 min)
    /// targets ~200 km; at ±100% tolerance the most distant candidate sits at
    /// ~400 km, so 400 km covers the whole ladder.
    private static let candidateRadiusKm: Double = 400
    private static let candidateLimit = 1500

    var selectedDestination: Destination? {
        guard destinations.indices.contains(selectedIndex) else { return nil }
        return destinations[selectedIndex]
    }

    var hasDestinations: Bool { !destinations.isEmpty }

    /// Estações "em alcance" (sólidas): índices 0...selectedIndex inclusive.
    var reachableCount: Int { destinations.isEmpty ? 0 : selectedIndex + 1 }

    /// Raio cosmético do anel no mapa, em metros — estilizado a partir do
    /// nominalKm da estação selecionada (não é distância geográfica real).
    var ringRadiusMeters: CLLocationDistance {
        guard let dest = selectedDestination else { return 0 }
        return Double(dest.nominalKm) * 1_000 * Self.ringScale
    }

    /// Multiplicador visual do anel (tunável).
    static let ringScale: Double = 1.0

    init(origin: Station? = nil,
         haptics: DetentHapticsService = DetentHaptics.make(),
         database: CityDatabase = .shared,
         homeCityStore: HomeCityStore = .shared) {
        self.haptics = haptics
        self.database = database
        self.homeCityStore = homeCityStore
        let resolved = homeCityStore.resolveOrigin(
            gpsCity: nil, gpsCountryCode: nil, gpsCoordinate: nil
        )
        self.origin = origin ?? resolved

        let defaults = UserDefaults.standard
        if let raw = defaults.string(forKey: "defaultScenario"), let s = FocusScenario(rawValue: raw) {
            scenario = s
        } else {
            scenario = .forest
        }
        if let raw = defaults.string(forKey: "defaultMapStyle"), let m = MapStyle(rawValue: raw) {
            mapStyle = m
        } else {
            mapStyle = .monochrome
        }
        mapShowLabels = defaults.object(forKey: "mapShowLabels") == nil
            ? true
            : defaults.bool(forKey: "mapShowLabels")

        scheduleLoad()
    }

    func prepareHaptics() { haptics.prepare() }

    /// Soft tick fired by the ruler view when the drag crosses a sub-tick between
    /// destinations. Doesn't change `selectedIndex` — purely tactile texture.
    func fineTick() { haptics.fineTick() }

    func beginInteraction(_ source: InteractionSource) { interactionSource = source }
    func endInteraction() { interactionSource = .none }

    /// The one mutator. Clamps to range, ignores no-op changes (breaks echo
    /// loops), and ticks only when the index actually moves.
    func select(_ index: Int, from source: InteractionSource) {
        guard !destinations.isEmpty else { return }
        let clamped = min(max(index, 0), destinations.count - 1)
        guard clamped != selectedIndex else { return }
        selectedIndex = clamped
        haptics.tick()
    }

    /// Push GPS-resolved city into the model. Used by the view when
    /// `CurrentCityResolver` finishes its reverse-geocode. Falls back to a
    /// continent guess via country code; if `HomeCityStore` has a manual city
    /// set, the manual choice still wins (resolved through `resolveOrigin`).
    func setGPSOrigin(city: String,
                      countryCode: String?,
                      coordinate: CLLocationCoordinate2D) {
        let resolved = homeCityStore.resolveOrigin(
            gpsCity: city, gpsCountryCode: countryCode, gpsCoordinate: coordinate
        )
        applyResolved(resolved)
    }

    /// Replays origin resolution against the current `HomeCityStore` state.
    /// Call this when the user changes their manual city in Settings.
    func refreshFromHomeCityStore() {
        let resolved = homeCityStore.resolveOrigin(
            gpsCity: nil, gpsCountryCode: nil, gpsCoordinate: nil
        )
        applyResolved(resolved)
    }

    private func applyResolved(_ newOrigin: Station) {
        let originChanged = newOrigin.lat != origin.lat
            || newOrigin.lon != origin.lon
        guard originChanged else { return }
        origin = newOrigin
        scheduleLoad()
    }

    private func scheduleLoad() {
        loaderTask?.cancel()
        let origin = origin
        let database = database
        loaderTask = Task { [weak self] in
            let candidates = await database.nearby(
                center: origin.coordinate,
                radiusKm: Self.candidateRadiusKm,
                limit: Self.candidateLimit
            )
            if Task.isCancelled { return }
            let ladder = Destination.makeLadder(origin: origin, candidates: candidates)
            await MainActor.run {
                guard let self else { return }
                self.applyLadder(ladder)
            }
        }
    }

    private func applyLadder(_ ladder: [Destination]) {
        destinations = ladder
        guard !ladder.isEmpty else {
            selectedIndex = 0
            return
        }
        let defaultIndex = ladder.firstIndex(where: { $0.minutes == 25 })
            ?? (ladder.count / 2)
        selectedIndex = min(defaultIndex, ladder.count - 1)
    }

    func makeTicket(departingAt departDate: Date = .now) -> Ticket? {
        guard let dest = selectedDestination else { return nil }
        return Ticket(
            scenario: scenario.rawValue,
            fromCode: origin.code, fromCity: origin.city,
            toCode: dest.station.code, toCity: dest.station.city,
            fromLat: origin.lat, fromLon: origin.lon,
            toLat: dest.station.lat, toLon: dest.station.lon,
            departDate: departDate,
            durationMinutes: dest.minutes,
            mapStyle: mapStyle.rawValue,
            code: Ticket.makeCode()
        )
    }
}
