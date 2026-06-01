import SwiftUI
import MapKit

/// A single completed leg to overlay on the cumulative map.
struct JourneyRoute: Identifiable, Equatable {
    let id: String
    let from: CLLocationCoordinate2D
    let to: CLLocationCoordinate2D

    static func == (lhs: JourneyRoute, rhs: JourneyRoute) -> Bool { lhs.id == rhs.id }
}

/// The cumulative "where you've travelled" map: every completed route drawn as a
/// geodesic polyline on a monochrome world map, with station dots at each end.
/// Re-fits to show all routes whenever the set changes.
struct JourneyMapView: UIViewRepresentable {
    let routes: [JourneyRoute]
    var style: MapStyle = .monochrome

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.preferredConfiguration = style.mapConfiguration(showLabels: false)
        map.isRotateEnabled = false
        map.isPitchEnabled = false
        map.showsCompass = false
        map.pointOfInterestFilter = .excludingAll
        context.coordinator.reload(map, routes: routes, animated: false)
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        guard context.coordinator.appliedIDs != routes.map(\.id) else { return }
        context.coordinator.reload(map, routes: routes, animated: true)
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, MKMapViewDelegate {
        var appliedIDs: [String] = []

        func reload(_ map: MKMapView, routes: [JourneyRoute], animated: Bool) {
            map.removeOverlays(map.overlays)
            map.removeAnnotations(map.annotations)

            for route in routes {
                let line = MKGeodesicPolyline(coordinates: [route.from, route.to], count: 2)
                map.addOverlay(line, level: .aboveRoads)

                let a = EndpointAnnotation(); a.coordinate = route.from; a.kind = .origin
                let b = EndpointAnnotation(); b.coordinate = route.to; b.kind = .destination
                map.addAnnotations([a, b])
            }

            appliedIDs = routes.map(\.id)
            fitAll(map, animated: animated)
        }

        private func fitAll(_ map: MKMapView, animated: Bool) {
            guard !map.overlays.isEmpty else { return }
            let rect = map.overlays.reduce(MKMapRect.null) { $0.union($1.boundingMapRect) }
            let inset = UIEdgeInsets(top: 120, left: 60, bottom: 120, right: 60)
            map.setVisibleMapRect(rect, edgePadding: inset, animated: animated)
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let line = overlay as? MKPolyline else {
                return MKOverlayRenderer(overlay: overlay)
            }
            let renderer = MKPolylineRenderer(polyline: line)
            renderer.strokeColor = UIColor.white.withAlphaComponent(0.85)
            renderer.lineWidth = 2.5
            renderer.lineCap = .round
            renderer.lineJoin = .round
            return renderer
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let endpoint = annotation as? EndpointAnnotation else { return nil }
            let id = "journeyEndpoint"
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: id)
                ?? MKAnnotationView(annotation: annotation, reuseIdentifier: id)
            view.annotation = annotation
            view.image = EndpointAnnotationView.dot(filled: endpoint.kind == .destination)
            view.centerOffset = .zero
            return view
        }
    }
}
