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

    /// Resolve the current phase against the wall clock.
    var phase: Phase {
        guard let ticket = activeTicket else { return .idle }
        return Date.now >= ticket.arrivalDate ? .arrived : .riding
    }

    func start(_ ticket: Ticket) {
        activeTicket = ticket
    }

    func clear() {
        activeTicket = nil
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
