import CoreLocation
import Foundation

/// Persisted home city — either picked manually in Settings or resolved from
/// the last successful GPS reverse-geocode. Encoded into UserDefaults under
/// the `home.manualCity` key by `HomeCityStore`.
struct HomeCity: Codable, Hashable {
    let geonameId: Int
    let name: String
    let countryCode: String
    let lat: Double
    let lon: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    init(geonameId: Int, name: String, countryCode: String, lat: Double, lon: Double) {
        self.geonameId = geonameId
        self.name = name
        self.countryCode = countryCode
        self.lat = lat
        self.lon = lon
    }

    init(city: City) {
        self.init(
            geonameId: city.geonameId,
            name: city.name,
            countryCode: city.countryCode,
            lat: city.lat,
            lon: city.lon
        )
    }
}
