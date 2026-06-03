import SwiftUI
import Observation

/// Owns the active focus-session ticket, persisting it as JSON in UserDefaults
/// so a ride survives backgrounding / force-quit.
@MainActor
@Observable
final class SessionStore {
    enum Phase: Equatable {
        case idle       // no active ticket
        case riding     // ticket exists, arrival still in the future
        case arrived    // ticket exists, duration already elapsed
    }

    private static let storageKey = "activeTicket"

    private(set) var activeTicket: Ticket? {
        didSet { persist() }
    }

    init() {
        load()
    }

    /// Resolve the current phase, pause-aware via `Ticket.isArrived()`.
    var phase: Phase {
        guard let ticket = activeTicket else { return .idle }
        return ticket.isArrived() ? .arrived : .riding
    }

    func start(_ ticket: Ticket) {
        activeTicket = ticket
    }

    func clear() {
        activeTicket = nil
    }

    /// Updates only the scenario tag on the active ticket. Used by the
    /// in-ride music selector so the choice survives backgrounding and
    /// flows into the saved Journey at arrival.
    func updateScenario(_ scenario: FocusScenario) {
        guard var ticket = activeTicket, ticket.scenario != scenario.rawValue else { return }
        ticket.scenario = scenario.rawValue
        activeTicket = ticket
    }

    /// Updates only the map style on the active ticket. Used by the in-ride
    /// map-style selector so the choice survives backgrounding and flows into
    /// the saved Journey at arrival. Mirrors `updateScenario`.
    func updateMapStyle(_ style: MapStyle) {
        guard var ticket = activeTicket, ticket.mapStyle != style.rawValue else { return }
        ticket.mapStyle = style.rawValue
        activeTicket = ticket
    }

    /// Persists pause-state changes on the active ticket. Used by
    /// `SessionViewModel.togglePause()` so the choice survives backgrounding.
    func updatePauseState(pausedAt: Date?, accumulatedPause: TimeInterval) {
        guard var ticket = activeTicket else { return }
        ticket.pausedAt = pausedAt
        ticket.accumulatedPause = accumulatedPause
        activeTicket = ticket
    }

    // MARK: - Persistence

    private func load() {
        guard
            let raw = UserDefaults.standard.string(forKey: Self.storageKey),
            let data = raw.data(using: .utf8),
            let ticket = try? JSONDecoder.ft.decode(Ticket.self, from: data)
        else { return }
        activeTicket = ticket
    }

    private func persist() {
        let defaults = UserDefaults.standard
        guard
            let ticket = activeTicket,
            let data = try? JSONEncoder.ft.encode(ticket),
            let raw = String(data: data, encoding: .utf8)
        else {
            defaults.removeObject(forKey: Self.storageKey)
            return
        }
        defaults.set(raw, forKey: Self.storageKey)
    }
}

extension JSONEncoder {
    static var ft: JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }
}

extension JSONDecoder {
    static var ft: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }
}
