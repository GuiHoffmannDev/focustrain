import Foundation

/// A snapshot of an in-progress focus journey. Persisted as JSON in `@AppStorage`
/// so a session can be resumed after backgrounding or a force-quit.
struct Ticket: Codable, Equatable, Hashable {
    var scenario: String        // FocusScenario.rawValue
    var fromCode: String
    var fromCity: String
    var toCode: String
    var toCity: String
    var fromLat: Double
    var fromLon: Double
    var toLat: Double
    var toLon: Double
    var departDate: Date        // anchor — elapsed time is recomputed on relaunch
    var durationMinutes: Int
    var mapStyle: String        // MapStyle.rawValue
    var code: String            // e.g. "FT-7K2Q"
    var seatCode: String?       // e.g. "01C" — picked at SeatPicker stage
    var focusMode: String?      // FocusMode.rawValue or custom preset name

    var arrivalDate: Date {
        departDate.addingTimeInterval(TimeInterval(durationMinutes) * 60)
    }

    var totalDuration: TimeInterval {
        TimeInterval(durationMinutes) * 60
    }

    static func makeCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        let suffix = String((0..<4).map { _ in chars.randomElement()! })
        return "FT-\(suffix)"
    }
}
