import SwiftUI
import Observation

/// Drives the compose-journey screen: a live ticket preview the user tunes by
/// picking a duration, a scenario, and re-rolling the route before departing.
/// Seeds itself from the onboarding-persisted defaults.
@MainActor
@Observable
final class ComposeJourneyViewModel {
    var duration: SessionDuration
    var scenario: FocusScenario
    var mapStyle: MapStyle

    private(set) var from: Station
    private(set) var to: Station

    init() {
        // Seed from onboarding prefs where available.
        let defaults = UserDefaults.standard

        if let raw = defaults.string(forKey: "defaultScenario"),
           let s = FocusScenario(rawValue: raw) {
            scenario = s
        } else {
            scenario = .forest
        }

        if let raw = defaults.string(forKey: "defaultMapStyle"),
           let m = MapStyle(rawValue: raw) {
            mapStyle = m
        } else {
            mapStyle = .monochrome
        }

        duration = .default

        let pair = StationPool.randomPair()
        from = pair.from
        to = pair.to
    }

    /// Picks a fresh random origin/destination pair.
    func reroll() {
        let pair = StationPool.randomPair()
        from = pair.from
        to = pair.to
    }

    /// Builds the active-session ticket for the current selections.
    func makeTicket(departingAt departDate: Date = .now) -> Ticket {
        Ticket(
            scenario: scenario.rawValue,
            fromCode: from.code,
            fromCity: from.city,
            toCode: to.code,
            toCity: to.city,
            fromLat: from.lat,
            fromLon: from.lon,
            toLat: to.lat,
            toLon: to.lon,
            departDate: departDate,
            durationMinutes: duration.minutes,
            mapStyle: mapStyle.rawValue,
            code: Ticket.makeCode()
        )
    }
}
