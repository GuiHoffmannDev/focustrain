import Foundation

enum SessionDuration: Int, CaseIterable, Identifiable {
    case quick   = 15
    case classic = 25
    case deep    = 45
    case long    = 60

    var id: Int { rawValue }

    var minutes: Int { rawValue }

    /// Short label shown on the duration chip, e.g. "25".
    var label: String { "\(rawValue)" }

    static var `default`: SessionDuration { .classic }
}
