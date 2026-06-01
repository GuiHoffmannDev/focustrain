import MapKit

extension MapStyle {
    /// Maps the user-facing style onto an MKMapView configuration.
    /// - Parameter showLabels: honors the onboarding `mapShowLabels` pref.
    func mapConfiguration(showLabels: Bool) -> MKMapConfiguration {
        switch self {
        case .monochrome:
            let config = MKStandardMapConfiguration(emphasisStyle: .muted)
            config.pointOfInterestFilter = showLabels ? .includingAll : .excludingAll
            config.showsTraffic = false
            return config

        case .standard:
            let config = MKStandardMapConfiguration()
            config.pointOfInterestFilter = showLabels ? .includingAll : .excludingAll
            config.showsTraffic = false
            return config

        case .terra:
            // Imagery basemap (pure satellite) reads as "earth/terrain".
            return MKImageryMapConfiguration()

        case .satellite:
            // Hybrid imagery: satellite + optional road/label overlay.
            let config = MKHybridMapConfiguration()
            config.pointOfInterestFilter = showLabels ? .includingAll : .excludingAll
            return config
        }
    }

    /// Whether this style needs a dark dimming overlay to sit behind the
    /// white route line + chrome (keeps monochrome readable).
    var needsDimmingOverlay: Bool {
        switch self {
        case .monochrome, .terra, .satellite: return true
        case .standard: return false
        }
    }
}
