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
}
