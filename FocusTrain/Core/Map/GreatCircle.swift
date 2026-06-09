import CoreLocation

/// Great-circle (spherical) helpers for placing the train along the route.
enum GreatCircle {
    /// Spherical interpolation between two coordinates at `fraction` ∈ [0, 1].
    static func interpolate(
        from a: CLLocationCoordinate2D,
        to b: CLLocationCoordinate2D,
        fraction f: Double
    ) -> CLLocationCoordinate2D {
        let f = min(max(f, 0), 1)

        let φ1 = a.latitude.toRadians, λ1 = a.longitude.toRadians
        let φ2 = b.latitude.toRadians, λ2 = b.longitude.toRadians

        let δ = angularDistance(a, b)
        guard δ > 1e-9 else { return a }

        let sinδ = sin(δ)
        let A = sin((1 - f) * δ) / sinδ
        let B = sin(f * δ) / sinδ

        let x = A * cos(φ1) * cos(λ1) + B * cos(φ2) * cos(λ2)
        let y = A * cos(φ1) * sin(λ1) + B * cos(φ2) * sin(λ2)
        let z = A * sin(φ1) + B * sin(φ2)

        let φ = atan2(z, (x * x + y * y).squareRoot())
        let λ = atan2(y, x)

        return CLLocationCoordinate2D(latitude: φ.toDegrees, longitude: λ.toDegrees)
    }

    /// Initial bearing (degrees, 0 = north) travelling from `a` toward `b`.
    static func bearing(
        from a: CLLocationCoordinate2D,
        to b: CLLocationCoordinate2D
    ) -> Double {
        let φ1 = a.latitude.toRadians, φ2 = b.latitude.toRadians
        let Δλ = (b.longitude - a.longitude).toRadians

        let y = sin(Δλ) * cos(φ2)
        let x = cos(φ1) * sin(φ2) - sin(φ1) * cos(φ2) * cos(Δλ)
        let θ = atan2(y, x)
        return (θ.toDegrees + 360).truncatingRemainder(dividingBy: 360)
    }

    /// Great-circle distance in kilometres between two coordinates (haversine).
    /// Allocation-free replacement for `CLLocation.distance(from:)` — used by the
    /// destination ladder and `CityDatabase` to refine the R-tree bounding box.
    static func distanceKm(
        _ a: CLLocationCoordinate2D,
        _ b: CLLocationCoordinate2D
    ) -> Double {
        earthRadiusKm * angularDistance(a, b)
    }

    /// Mean Earth radius (km) — IUGG, matches `CLLocation`'s sphere closely.
    static let earthRadiusKm = 6371.0088

    /// Angular distance (radians) between two coordinates via the haversine.
    private static func angularDistance(
        _ a: CLLocationCoordinate2D,
        _ b: CLLocationCoordinate2D
    ) -> Double {
        let φ1 = a.latitude.toRadians, φ2 = b.latitude.toRadians
        let Δφ = (b.latitude - a.latitude).toRadians
        let Δλ = (b.longitude - a.longitude).toRadians
        let h = sin(Δφ / 2) * sin(Δφ / 2)
            + cos(φ1) * cos(φ2) * sin(Δλ / 2) * sin(Δλ / 2)
        return 2 * atan2(h.squareRoot(), (1 - h).squareRoot())
    }
}

private extension Double {
    var toRadians: Double { self * .pi / 180 }
    var toDegrees: Double { self * 180 / .pi }
}
