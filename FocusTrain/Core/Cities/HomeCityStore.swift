import CoreLocation
import Foundation
import Observation

/// Persists the user's chosen home city (Settings → "Cidade base") and computes
/// the origin used by the destination ladder. Resolution order:
/// 1. Manually picked city, if any.
/// 2. GPS-resolved city from `CurrentCityResolver`, if available.
/// 3. `Station.defaultOrigin` (São Paulo) as last resort.
@MainActor
@Observable
final class HomeCityStore {
    static let shared = HomeCityStore()

    private static let key = "home.manualCity"

    private(set) var manualCity: HomeCity?

    private let defaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.defaults = userDefaults
        if let data = userDefaults.data(forKey: Self.key),
           let decoded = try? JSONDecoder().decode(HomeCity.self, from: data) {
            self.manualCity = decoded
        }
    }

    func setManualCity(_ city: HomeCity?) {
        manualCity = city
        if let city, let encoded = try? JSONEncoder().encode(city) {
            defaults.set(encoded, forKey: Self.key)
        } else {
            defaults.removeObject(forKey: Self.key)
        }
    }

    /// Resolves the origin station. Order: manual city, then GPS-resolved city,
    /// then `Station.defaultOrigin` (São Paulo) as last resort. `gpsCountryCode`
    /// is accepted for call-site symmetry but no longer affects the result (the
    /// continent filter was dropped — candidates now come from a radius query).
    func resolveOrigin(gpsCity: String?,
                       gpsCountryCode: String?,
                       gpsCoordinate: CLLocationCoordinate2D?) -> Station {
        if let manual = manualCity {
            return Station.make(city: manual.name, coordinate: manual.coordinate)
        }
        if let cityName = gpsCity, let coord = gpsCoordinate {
            return Station.make(city: cityName, coordinate: coord)
        }
        return Station.defaultOrigin
    }
}
