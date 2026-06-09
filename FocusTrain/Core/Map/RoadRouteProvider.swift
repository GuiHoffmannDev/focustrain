import Foundation
import MapKit
import CoreLocation

/// Fetches a road-following polyline between two coordinates via
/// `MKDirections`, giving the live-session map a real highway/BR-shaped path
/// (instead of an airplane-style straight geodesic). Cached in memory so the
/// user toggling between durations doesn't refetch the same route.
actor RoadRouteProvider {
    static let shared = RoadRouteProvider()

    private struct CacheKey: Hashable {
        let fromLatRounded: Int
        let fromLonRounded: Int
        let toLatRounded: Int
        let toLonRounded: Int

        init(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) {
            fromLatRounded = Int((from.latitude * 1000).rounded())
            fromLonRounded = Int((from.longitude * 1000).rounded())
            toLatRounded = Int((to.latitude * 1000).rounded())
            toLonRounded = Int((to.longitude * 1000).rounded())
        }
    }

    enum ProviderError: Error {
        case noRoute
    }

    private var cache: [CacheKey: MKPolyline] = [:]

    func route(
        from: CLLocationCoordinate2D,
        to: CLLocationCoordinate2D
    ) async throws -> MKPolyline {
        let key = CacheKey(from: from, to: to)
        if let hit = cache[key] { return hit }

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: from))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: to))
        request.transportType = .automobile
        request.requestsAlternateRoutes = false

        let response = try await MKDirections(request: request).calculate()
        guard let polyline = response.routes.first?.polyline else {
            throw ProviderError.noRoute
        }
        cache[key] = polyline
        return polyline
    }
}
