import SwiftUI
import MapKit

/// The Home backdrop: a regional map centred on the user's city. Nothing else —
/// no station pins, no preview lines, no history overlays. The pulsing marker is
/// a SwiftUI overlay (`PulsingPin`) composed on top in `HomeView`.
struct GlobeHomeView: UIViewRepresentable {
    let center: CLLocationCoordinate2D
    var style: MapStyle = .satellite
    var showLabels: Bool = false

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.preferredConfiguration = style.mapConfiguration(showLabels: showLabels)
        context.coordinator.appliedStyle = style
        context.coordinator.appliedShowLabels = showLabels
        map.isZoomEnabled = false
        map.isScrollEnabled = false
        map.isRotateEnabled = false
        map.isPitchEnabled = false
        map.showsCompass = false
        map.showsScale = false
        map.showsBuildings = false
        map.pointOfInterestFilter = .excludingAll

        context.coordinator.applyCamera(to: map, center: center, animated: false)
        context.coordinator.appliedCenter = center
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        let coordinator = context.coordinator
        if coordinator.appliedStyle != style || coordinator.appliedShowLabels != showLabels {
            map.preferredConfiguration = style.mapConfiguration(showLabels: showLabels)
            coordinator.appliedStyle = style
            coordinator.appliedShowLabels = showLabels
        }
        let centerChanged = coordinator.appliedCenter == nil
            || coordinator.appliedCenter!.latitude != center.latitude
            || coordinator.appliedCenter!.longitude != center.longitude
        if centerChanged {
            coordinator.applyCamera(to: map, center: center, animated: true)
            coordinator.appliedCenter = center
        }
    }

    // MARK: - Coordinator

    final class Coordinator {
        var appliedCenter: CLLocationCoordinate2D?
        var appliedStyle: MapStyle?
        var appliedShowLabels: Bool?

        /// Broad regional zoom around the user's city.
        func applyCamera(
            to map: MKMapView,
            center: CLLocationCoordinate2D,
            animated: Bool
        ) {
            let region = MKCoordinateRegion(
                center: center,
                latitudinalMeters: 2_000_000,
                longitudinalMeters: 2_000_000
            )
            map.setRegion(region, animated: animated)
        }
    }
}
