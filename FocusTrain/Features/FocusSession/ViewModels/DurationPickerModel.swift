import SwiftUI
import Observation
import CoreLocation

/// Single source of truth for the destination/duration picker. `selectedIndex`
/// into `destinations` is the only stored selection; everything visual derives
/// from it. Seeds scenario/mapStyle from onboarding defaults like the old
/// ComposeJourneyViewModel, and builds the active-session Ticket.
@MainActor
@Observable
final class DurationPickerModel {
    enum InteractionSource: Equatable { case none, ruler, radar, carousel }

    let destinations: [Destination]
    private(set) var origin: Station
    private(set) var selectedIndex: Int
    var interactionSource: InteractionSource = .none

    var scenario: FocusScenario
    var mapStyle: MapStyle

    private let haptics: DetentHapticsService

    var selectedDestination: Destination { destinations[selectedIndex] }

    init(destinations: [Destination] = Destination.ladder,
         origin: Station? = nil,
         haptics: DetentHapticsService = DetentHaptics.make()) {
        self.destinations = destinations
        self.haptics = haptics
        self.origin = origin ?? StationPool.all.randomElement()!

        // Default to 25 min (classic) if present, else the middle stop.
        self.selectedIndex = destinations.firstIndex(where: { $0.minutes == 25 })
            ?? (destinations.count / 2)

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
    }

    func prepareHaptics() { haptics.prepare() }

    func beginInteraction(_ source: InteractionSource) { interactionSource = source }
    func endInteraction() { interactionSource = .none }

    /// The one mutator. Clamps to range, ignores no-op changes (breaks echo
    /// loops), and ticks only when the index actually moves.
    func select(_ index: Int, from source: InteractionSource) {
        let clamped = min(max(index, 0), destinations.count - 1)
        guard clamped != selectedIndex else { return }
        selectedIndex = clamped
        haptics.tick()
    }

    /// Origin = the user's current city when available (set by the view from
    /// CurrentCityResolver); otherwise the random fallback chosen in init.
    func setOrigin(city: String, coordinate: CLLocationCoordinate2D) {
        origin = Self.originStation(city: city, coordinate: coordinate)
    }

    static func originStation(city: String, coordinate: CLLocationCoordinate2D) -> Station {
        let upper = city.uppercased().unicodeScalars.filter { CharacterSet.uppercaseLetters.contains($0) }
        let code = String(String(String.UnicodeScalarView(upper)).prefix(3))
        return Station(code: code.isEmpty ? "ORG" : code,
                       city: city,
                       lat: coordinate.latitude,
                       lon: coordinate.longitude)
    }

    func makeTicket(departingAt departDate: Date = .now) -> Ticket {
        let dest = selectedDestination
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

#if DEBUG
#Preview("DurationPickerModel self-check") {
    let m = DurationPickerModel(haptics: NoopDetentService())
    // clamp
    m.select(999, from: .ruler); let clampHi = m.selectedIndex == m.destinations.count - 1
    m.select(-5, from: .ruler);  let clampLo = m.selectedIndex == 0
    // dedup: selecting the same index twice keeps it put
    m.select(3, from: .radar); let after = m.selectedIndex; m.select(3, from: .carousel)
    let dedup = m.selectedIndex == after && after == 3
    // ticket reflects selection
    m.select(m.destinations.firstIndex { $0.minutes == 90 }!, from: .ruler)
    let t = m.makeTicket()
    let ticketOK = t.durationMinutes == 90 && t.toCode == "TYO" && t.fromCode == m.origin.code
    let pass = clampHi && clampLo && dedup && ticketOK
    return VStack(alignment: .leading, spacing: 6) {
        Text(pass ? "PASS ✓" : "FAIL ✗").font(.title.bold()).foregroundStyle(pass ? .green : .red)
        Text("clampHi=\(clampHi) clampLo=\(clampLo) dedup=\(dedup) ticket=\(ticketOK)").font(.caption.monospaced())
        Text("ticket: \(t.fromCode)→\(t.toCode) \(t.durationMinutes)m").font(.caption2.monospaced())
    }.padding()
}
#endif
