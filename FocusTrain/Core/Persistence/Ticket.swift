import Foundation

/// A snapshot of an in-progress focus journey. Persisted as JSON in
/// `UserDefaults` so a session can be resumed after backgrounding or a
/// force-quit. The optional `pausedAt` + accumulated pause budget let
/// the live `elapsed` recompute correctly when the app re-enters
/// foreground after a pause.
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

    // MARK: - Pause state (new in Phase 2)

    /// When the current pause began. `nil` means the session is running.
    var pausedAt: Date? = nil

    /// Sum of every prior pause interval already consumed by the session.
    /// Does NOT include the currently-open pause (if any) — that slice is
    /// computed live from `pausedAt`.
    var accumulatedPause: TimeInterval = 0

    // MARK: - Derived

    /// Scheduled arrival on the wall clock if the user never pauses.
    /// Pause does NOT shift this value — it represents the original
    /// promise on the boarding pass. The pause-aware "is this session
    /// actually over?" decision lives in `isArrived(at:)`.
    var arrivalDate: Date {
        departDate.addingTimeInterval(TimeInterval(durationMinutes) * 60)
    }

    /// Pause-aware completion check. Subtracts both the budget of prior
    /// closed pauses and the open pause slice (if any) from wall-clock
    /// elapsed before comparing against `totalDuration`. Use this anywhere
    /// you previously compared `Date.now >= arrivalDate`.
    func isArrived(at now: Date = .now) -> Bool {
        let currentPauseSlice = pausedAt.map { max(0, now.timeIntervalSince($0)) } ?? 0
        let elapsed = max(
            0,
            now.timeIntervalSince(departDate) - accumulatedPause - currentPauseSlice
        )
        return elapsed >= totalDuration
    }

    var totalDuration: TimeInterval {
        TimeInterval(durationMinutes) * 60
    }

    static func makeCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        let suffix = String((0..<4).map { _ in chars.randomElement()! })
        return "FT-\(suffix)"
    }

    // MARK: - Backwards-compatible decode

    /// Auto-synthesized decode would throw if `accumulatedPause` is missing
    /// from the JSON stored on disk for a pre-Phase-2 session. This custom
    /// initializer defaults the new fields so existing tickets decode cleanly.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        scenario          = try c.decode(String.self, forKey: .scenario)
        fromCode          = try c.decode(String.self, forKey: .fromCode)
        fromCity          = try c.decode(String.self, forKey: .fromCity)
        toCode            = try c.decode(String.self, forKey: .toCode)
        toCity            = try c.decode(String.self, forKey: .toCity)
        fromLat           = try c.decode(Double.self, forKey: .fromLat)
        fromLon           = try c.decode(Double.self, forKey: .fromLon)
        toLat             = try c.decode(Double.self, forKey: .toLat)
        toLon             = try c.decode(Double.self, forKey: .toLon)
        departDate        = try c.decode(Date.self,   forKey: .departDate)
        durationMinutes   = try c.decode(Int.self,    forKey: .durationMinutes)
        mapStyle          = try c.decode(String.self, forKey: .mapStyle)
        code              = try c.decode(String.self, forKey: .code)
        seatCode          = try c.decodeIfPresent(String.self, forKey: .seatCode)
        focusMode         = try c.decodeIfPresent(String.self, forKey: .focusMode)
        pausedAt          = try c.decodeIfPresent(Date.self,   forKey: .pausedAt)
        accumulatedPause  = try c.decodeIfPresent(TimeInterval.self, forKey: .accumulatedPause) ?? 0
    }

    /// Default memberwise-style initializer preserved for direct construction.
    init(
        scenario: String,
        fromCode: String,
        fromCity: String,
        toCode: String,
        toCity: String,
        fromLat: Double,
        fromLon: Double,
        toLat: Double,
        toLon: Double,
        departDate: Date,
        durationMinutes: Int,
        mapStyle: String,
        code: String,
        seatCode: String? = nil,
        focusMode: String? = nil,
        pausedAt: Date? = nil,
        accumulatedPause: TimeInterval = 0
    ) {
        self.scenario = scenario
        self.fromCode = fromCode
        self.fromCity = fromCity
        self.toCode = toCode
        self.toCity = toCity
        self.fromLat = fromLat
        self.fromLon = fromLon
        self.toLat = toLat
        self.toLon = toLon
        self.departDate = departDate
        self.durationMinutes = durationMinutes
        self.mapStyle = mapStyle
        self.code = code
        self.seatCode = seatCode
        self.focusMode = focusMode
        self.pausedAt = pausedAt
        self.accumulatedPause = accumulatedPause
    }
}