import Foundation
import CoreLocation
import SwiftUI

/// Resolves the user's current city via CoreLocation + reverse geocoding.
/// Publishes the city name (or a graceful fallback) so the Home greeting can
/// read it directly. Holds onto the last result across permission flips so the
/// UI never flashes "Traveler" once a city has been resolved.
@MainActor
@Observable
final class CurrentCityResolver: NSObject, CLLocationManagerDelegate {
    enum Status { case idle, requesting, resolved, denied, failed }

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var pendingResolve = false

    var cityName: String?
    var coordinate: CLLocationCoordinate2D?
    var status: Status = .idle

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    /// Call once when the Home view appears.
    func bootstrap() {
        switch manager.authorizationStatus {
        case .notDetermined:
            status = .requesting
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            requestLocation()
        case .denied, .restricted:
            status = .denied
        @unknown default:
            status = .failed
        }
    }

    private func requestLocation() {
        guard !pendingResolve else { return }
        pendingResolve = true
        status = .requesting
        manager.requestLocation()
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let auth = manager.authorizationStatus
        Task { @MainActor in
            switch auth {
            case .authorizedAlways, .authorizedWhenInUse:
                self.requestLocation()
            case .denied, .restricted:
                self.status = .denied
            case .notDetermined:
                break
            @unknown default:
                self.status = .failed
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        Task { @MainActor in
            self.pendingResolve = false
            self.coordinate = loc.coordinate
            await self.reverseGeocode(loc)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.pendingResolve = false
            if self.cityName == nil { self.status = .failed }
        }
    }

    private func reverseGeocode(_ location: CLLocation) async {
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let p = placemarks.first {
                cityName = p.locality ?? p.subAdministrativeArea ?? p.administrativeArea ?? p.country
                status = .resolved
            } else {
                status = .failed
            }
        } catch {
            status = .failed
        }
    }
}

/// Picks the greeting key (good morning / afternoon / evening) for `date`.
enum GreetingPeriod {
    static func key(for date: Date = .now, calendar: Calendar = .current) -> String {
        let hour = calendar.component(.hour, from: date)
        switch hour {
        case 5..<12:  return "home.greeting.morning"
        case 12..<18: return "home.greeting.afternoon"
        default:      return "home.greeting.evening"
        }
    }
}
