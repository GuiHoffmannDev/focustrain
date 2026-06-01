import Foundation
import SwiftData

/// A completed focus journey, persisted via SwiftData for history + streaks.
@Model
final class Journey {
    var date: Date
    var scenario: String
    var fromCode: String
    var fromCity: String
    var toCode: String
    var toCity: String
    var fromLat: Double
    var fromLon: Double
    var toLat: Double
    var toLon: Double
    var durationMinutes: Int
    var code: String
    var seatCode: String?
    var focusMode: String?

    init(
        date: Date,
        scenario: String,
        fromCode: String,
        fromCity: String,
        toCode: String,
        toCity: String,
        fromLat: Double,
        fromLon: Double,
        toLat: Double,
        toLon: Double,
        durationMinutes: Int,
        code: String,
        seatCode: String? = nil,
        focusMode: String? = nil
    ) {
        self.date = date
        self.scenario = scenario
        self.fromCode = fromCode
        self.fromCity = fromCity
        self.toCode = toCode
        self.toCity = toCity
        self.fromLat = fromLat
        self.fromLon = fromLon
        self.toLat = toLat
        self.toLon = toLon
        self.durationMinutes = durationMinutes
        self.code = code
        self.seatCode = seatCode
        self.focusMode = focusMode
    }
}

extension Journey {
    /// Build a completed Journey from the active session ticket.
    convenience init(ticket: Ticket, completedAt: Date = .now) {
        self.init(
            date: completedAt,
            scenario: ticket.scenario,
            fromCode: ticket.fromCode,
            fromCity: ticket.fromCity,
            toCode: ticket.toCode,
            toCity: ticket.toCity,
            fromLat: ticket.fromLat,
            fromLon: ticket.fromLon,
            toLat: ticket.toLat,
            toLon: ticket.toLon,
            durationMinutes: ticket.durationMinutes,
            code: ticket.code,
            seatCode: ticket.seatCode,
            focusMode: ticket.focusMode
        )
    }
}
