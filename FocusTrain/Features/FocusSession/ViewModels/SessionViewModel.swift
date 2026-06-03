import SwiftUI
import Observation
import CoreLocation

/// Drives the live ride: a wall-clock-anchored timer that derives progress,
/// remaining time, and the train's position along the great-circle route.
/// Because it anchors on `ticket.departDate`, it resumes correctly after the
/// app is backgrounded or force-quit.
@MainActor
@Observable
final class SessionViewModel {
    private(set) var ticket: Ticket
    weak var store: SessionStore?

    /// Called once when the journey's duration has fully elapsed.
    var onArrive: () -> Void = {}

    private(set) var now: Date = .now
    private var timer: Timer?

    init(ticket: Ticket, store: SessionStore? = nil) {
        self.ticket = ticket
        self.store = store
    }

    // MARK: - Derived state

    var fromCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: ticket.fromLat, longitude: ticket.fromLon)
    }

    var toCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: ticket.toLat, longitude: ticket.toLon)
    }

    var elapsed: TimeInterval {
        let raw = now.timeIntervalSince(ticket.departDate)
            - ticket.accumulatedPause
            - currentPauseSlice
        return max(0, raw)
    }

    var isPaused: Bool { ticket.pausedAt != nil }

    var currentPauseSlice: TimeInterval {
        guard let pausedAt = ticket.pausedAt else { return 0 }
        return max(0, now.timeIntervalSince(pausedAt))
    }

    var remaining: TimeInterval {
        max(0, ticket.totalDuration - elapsed)
    }

    /// Journey completion in [0, 1].
    var progress: Double {
        guard ticket.totalDuration > 0 else { return 1 }
        return min(1, elapsed / ticket.totalDuration)
    }

    var isArrived: Bool { remaining <= 0 }

    /// Interpolated train position along the geodesic.
    var trainCoordinate: CLLocationCoordinate2D {
        GreatCircle.interpolate(from: fromCoordinate, to: toCoordinate, fraction: progress)
    }

    /// "MM:SS" countdown of the time remaining.
    var remainingText: String {
        let total = Int(remaining.rounded())
        return String(format: "%02d:%02d", total / 60, total % 60)
    }

    /// Bottom-tile copy: "N min" for ≥1 minute, "<1 min" otherwise.
    /// Always uses minutes — no MM:SS — because the tile is small.
    var remainingMinutesText: String {
        if remaining < 60 {
            return NSLocalizedString("session.minutes.lt1", comment: "Shown when under one minute remains")
        }
        let minutes = Int((remaining / 60).rounded())
        let unit = NSLocalizedString("session.minutes.unit", comment: "Short minutes unit")
        return "\(minutes) \(unit)"
    }

    /// Total great-circle distance of the route, in metres.
    var totalDistance: CLLocationDistance {
        let a = CLLocation(latitude: ticket.fromLat, longitude: ticket.fromLon)
        let b = CLLocation(latitude: ticket.toLat, longitude: ticket.toLon)
        return a.distance(from: b)
    }

    /// Localized "N km" of distance still to travel.
    var remainingDistanceText: String {
        let km = (totalDistance * (1 - progress)) / 1000
        return String(format: "%.0f km", km.rounded())
    }

    var scenario: FocusScenario {
        FocusScenario(rawValue: ticket.scenario) ?? .forest
    }

    var mapStyle: MapStyle {
        MapStyle(rawValue: ticket.mapStyle) ?? .monochrome
    }

    // MARK: - Lifecycle

    func start() {
        tick()
        guard timer == nil else { return }
        let t = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        t.tolerance = 0.1
        timer = t
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    /// Re-anchor against the wall clock (call when returning to foreground).
    func refresh() {
        tick()
    }

    private func tick() {
        now = .now
        if isArrived {
            stop()
            onArrive()
        }
    }

    func togglePause() {
        if ticket.pausedAt != nil {
            ticket.accumulatedPause += currentPauseSlice
            ticket.pausedAt = nil
        } else {
            ticket.pausedAt = now
        }
        store?.updatePauseState(
            pausedAt: ticket.pausedAt,
            accumulatedPause: ticket.accumulatedPause
        )
    }
}
