import Foundation

/// Read-only formatting wrapper around `Ticket` for the Boarding Pass screen.
/// Keeps date/distance/duration formatting in one place so views stay declarative.
struct BoardingPassDisplay {
    let ticket: Ticket

    init(_ ticket: Ticket) { self.ticket = ticket }

    var fromCode: String { ticket.fromCode }
    var toCode: String { ticket.toCode }
    var fromCity: String { ticket.fromCity }
    var toCity: String { ticket.toCity }
    var code: String { ticket.code }
    var seat: String { ticket.seatCode ?? "—" }

    var durationLabel: String {
        let m = ticket.durationMinutes
        let h = m / 60, mm = m % 60
        if h == 0 { return "\(mm)m" }
        if mm == 0 { return "\(h)h" }
        return "\(h)h \(mm)m"
    }

    var durationAccessibility: String {
        let m = ticket.durationMinutes
        let h = m / 60, mm = m % 60
        var parts: [String] = []
        if h > 0 { parts.append("\(h) \(h == 1 ? "hora" : "horas")") }
        if mm > 0 { parts.append("\(mm) \(mm == 1 ? "minuto" : "minutos")") }
        return parts.joined(separator: " e ")
    }

    var boardingLabel: String {
        let boarding = ticket.departDate.addingTimeInterval(-30 * 60)
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: boarding)
    }

    var dateLabel: String {
        let f = DateFormatter()
        f.dateFormat = "dd MMM"
        return f.string(from: ticket.departDate).uppercased()
    }

    /// Great-circle distance in km between origin and destination.
    var distanceKm: Int {
        let R = 6371.0
        let φ1 = ticket.fromLat * .pi / 180
        let φ2 = ticket.toLat * .pi / 180
        let Δφ = (ticket.toLat - ticket.fromLat) * .pi / 180
        let Δλ = (ticket.toLon - ticket.fromLon) * .pi / 180
        let h = sin(Δφ / 2) * sin(Δφ / 2)
            + cos(φ1) * cos(φ2) * sin(Δλ / 2) * sin(Δλ / 2)
        let c = 2 * atan2(h.squareRoot(), (1 - h).squareRoot())
        return Int((R * c).rounded())
    }

    var distanceLabel: String { "\(distanceKm) km" }

    var accessibilitySummary: String {
        "Voo de \(fromCity) para \(toCity), \(durationAccessibility), assento \(seat). Embarque \(boardingLabel)."
    }
}
