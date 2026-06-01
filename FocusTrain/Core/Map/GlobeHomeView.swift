import SwiftUI
import MapKit

/// The cinematic "globe" backdrop behind the Home hero.
///
/// Implementation note: MapKit doesn't expose a true orthographic globe
/// projection, so we approximate the look with a very high-altitude
/// `MKMapCamera` centred on the user's city. Dark imagery basemap, no chrome,
/// no interaction — purely visual. Every completed `JourneyRoute` is drawn as
/// a white geodesic polyline so the user sees where they've ridden.
struct GlobeHomeView: UIViewRepresentable {
    let center: CLLocationCoordinate2D
    let routes: [JourneyRoute]
    var altitude: CLLocationDistance = 8_000_000

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.preferredConfiguration = darkImagery()
        map.isZoomEnabled = false
        map.isScrollEnabled = false
        map.isRotateEnabled = false
        map.isPitchEnabled = false
        map.showsCompass = false
        map.showsScale = false
        map.showsBuildings = false
        map.pointOfInterestFilter = .excludingAll
        map.overrideUserInterfaceStyle = .dark

        context.coordinator.apply(routes: routes, on: map)
        applyCamera(map)
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        let coordinator = context.coordinator
        if coordinator.appliedCenter == nil
            || coordinator.appliedCenter!.latitude != center.latitude
            || coordinator.appliedCenter!.longitude != center.longitude {
            applyCamera(map)
        }
        if coordinator.appliedIDs != routes.map(\.id) {
            coordinator.apply(routes: routes, on: map)
        }
    }

    private func applyCamera(_ map: MKMapView) {
        let cam = MKMapCamera(lookingAtCenter: center,
                              fromDistance: altitude,
                              pitch: 0,
                              heading: 0)
        map.setCamera(cam, animated: false)
    }

    private func darkImagery() -> MKMapConfiguration {
        let config = MKHybridMapConfiguration()
        config.pointOfInterestFilter = .excludingAll
        return config
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, MKMapViewDelegate {
        var appliedIDs: [String] = []
        var appliedCenter: CLLocationCoordinate2D?

        func apply(routes: [JourneyRoute], on map: MKMapView) {
            map.removeOverlays(map.overlays)
            for r in routes {
                let line = MKGeodesicPolyline(coordinates: [r.from, r.to], count: 2)
                map.addOverlay(line, level: .aboveLabels)
            }
            appliedIDs = routes.map(\.id)
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let line = overlay as? MKPolyline else {
                return MKOverlayRenderer(overlay: overlay)
            }
            let r = MKPolylineRenderer(polyline: line)
            r.strokeColor = UIColor.white.withAlphaComponent(0.85)
            r.lineWidth = 2
            r.lineCap = .round
            r.lineJoin = .round
            return r
        }
    }
}
