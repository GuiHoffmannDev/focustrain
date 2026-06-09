import Foundation
import CoreLocation

/// A single stop on the train system: city name + 3-letter code + coordinates.
/// Stations are generated procedurally around the user's origin by
/// `FictionalStationGenerator`.
struct Station: Hashable {
    let code: String
    let city: String
    let lat: Double
    let lon: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}

extension Station {
    /// Default origin when the user denies (or hasn't yet granted) location.
    static let defaultOrigin = Station(
        code: "SAO",
        city: "São Paulo",
        lat: -23.5505,
        lon: -46.6333
    )

    /// Builds a Station from a resolved city + coordinate. The 3-letter `code`
    /// is the first three uppercase letters of the city name (fallback `ORG`
    /// if the name has no uppercase characters).
    static func make(city: String, coordinate: CLLocationCoordinate2D) -> Station {
        let upper = city.uppercased().unicodeScalars
            .filter { CharacterSet.uppercaseLetters.contains($0) }
        let code = String(String(String.UnicodeScalarView(upper)).prefix(3))
        return Station(
            code: code.isEmpty ? "ORG" : code,
            city: city,
            lat: coordinate.latitude,
            lon: coordinate.longitude
        )
    }
}
