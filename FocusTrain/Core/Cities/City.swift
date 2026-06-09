import CoreLocation
import Foundation

/// One row from the bundled GeoNames cities5000 dataset (cities with population
/// ≥ 5000). Coordinates and population come straight from GeoNames; lat/lon are
/// stored with 4-decimal precision (~10m), well below the bucket tolerance.
struct City: Hashable, Codable {
    let geonameId: Int
    let name: String
    let asciiName: String
    let countryCode: String
    let lat: Double
    let lon: Double
    let population: Int

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}
