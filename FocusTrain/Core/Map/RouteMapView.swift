import SwiftUI
import MapKit

/// The live-session map: a real road-following polyline (MKDirections,
/// `.automobile`) between the two cities, with a glowing train annotation that
/// advances along the polyline by arc length and rotates to face the current
/// segment. While the road route is being fetched (or if MKDirections fails),
/// the view falls back to a straight geodesic so the train is never homeless.
struct RouteMapView: UIViewRepresentable {
    let from: CLLocationCoordinate2D
    let to: CLLocationCoordinate2D
    let fraction: Double
    let style: MapStyle
    let showLabels: Bool
    let follow: Bool

    /// Camera eye distance (metres) when following the train. Tight enough that
    /// the train fills the frame and the road slides past underneath it — the
    /// "I'm right there, locked in" feel — rather than a far regional overview.
    private static let followDistance: CLLocationDistance = 20_000

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.preferredConfiguration = style.mapConfiguration(showLabels: showLabels)
        map.isRotateEnabled = false
        map.isPitchEnabled = false
        map.showsCompass = false
        map.pointOfInterestFilter = showLabels ? .includingAll : .excludingAll

        // Geodesic placeholder so the train has something to ride while the
        // road route is being fetched.
        let placeholder = MKGeodesicPolyline(coordinates: [from, to], count: 2)
        map.addOverlay(placeholder, level: .aboveRoads)
        context.coordinator.activeOverlay = placeholder
        context.coordinator.samples = PolylineSamples(polyline: placeholder)
        context.coordinator.appliedEndpoints = (from, to)

        // Train annotation.
        let train = TrainAnnotation()
        train.coordinate = context.coordinator.samples?.point(at: fraction)?.coordinate ?? from
        map.addAnnotation(train)
        context.coordinator.train = train

        // Endpoint dots.
        let origin = EndpointAnnotation(); origin.coordinate = from; origin.kind = .origin
        let dest = EndpointAnnotation(); dest.coordinate = to; dest.kind = .destination
        map.addAnnotations([origin, dest])

        context.coordinator.fitRoute(map, animated: false)
        context.coordinator.fetchRoadRoute(for: map, from: from, to: to)
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        let coord = context.coordinator

        // Style changes.
        if coord.appliedStyle != style || coord.appliedLabels != showLabels {
            map.preferredConfiguration = style.mapConfiguration(showLabels: showLabels)
            map.pointOfInterestFilter = showLabels ? .includingAll : .excludingAll
            coord.appliedStyle = style
            coord.appliedLabels = showLabels
        }

        // Re-fetch when endpoints change.
        if let applied = coord.appliedEndpoints,
           (applied.from.latitude != from.latitude
            || applied.from.longitude != from.longitude
            || applied.to.latitude != to.latitude
            || applied.to.longitude != to.longitude) {
            coord.appliedEndpoints = (from, to)
            // Replace overlay with a fresh geodesic placeholder while fetching.
            if let active = coord.activeOverlay { map.removeOverlay(active) }
            let placeholder = MKGeodesicPolyline(coordinates: [from, to], count: 2)
            map.addOverlay(placeholder, level: .aboveRoads)
            coord.activeOverlay = placeholder
            coord.samples = PolylineSamples(polyline: placeholder)
            coord.didFitRoute = false
            coord.fetchRoadRoute(for: map, from: from, to: to)
        }

        // Advance the train smoothly along the current polyline.
        if let sample = coord.samples?.point(at: fraction), let train = coord.train {
            UIView.animate(withDuration: 0.5) {
                train.coordinate = sample.coordinate
            }
            if let view = map.view(for: train) as? TrainAnnotationView {
                view.applyBearing(sample.bearing)
            }
            coord.currentBearing = sample.bearing
        }

        // Camera behaviour. North-up: only the train icon rotates, never the map.
        if follow, let sample = coord.samples?.point(at: fraction) {
            let camera = MKMapCamera(
                lookingAtCenter: sample.coordinate,
                fromDistance: Self.followDistance,
                pitch: 0,
                heading: 0
            )
            map.setCamera(camera, animated: true)
            coord.didFitRoute = false
        } else if !coord.didFitRoute {
            coord.fitRoute(map, animated: true)
            coord.didFitRoute = true
        }
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, MKMapViewDelegate {
        var activeOverlay: MKPolyline?
        var samples: PolylineSamples?
        var train: TrainAnnotation?
        var appliedStyle: MapStyle?
        var appliedLabels: Bool?
        var appliedEndpoints: (from: CLLocationCoordinate2D, to: CLLocationCoordinate2D)?
        var didFitRoute = false
        var currentBearing: CLLocationDirection = 0
        private var inFlightFetch: Task<Void, Never>?

        func fitRoute(_ map: MKMapView, animated: Bool) {
            guard let active = activeOverlay else { return }
            let inset = UIEdgeInsets(top: 120, left: 80, bottom: 200, right: 80)
            map.setVisibleMapRect(
                active.boundingMapRect,
                edgePadding: inset,
                animated: animated
            )
        }

        func fetchRoadRoute(for map: MKMapView, from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) {
            inFlightFetch?.cancel()
            inFlightFetch = Task { [weak self, weak map] in
                guard let map else { return }
                do {
                    let polyline = try await RoadRouteProvider.shared.route(from: from, to: to)
                    if Task.isCancelled { return }
                    await MainActor.run {
                        guard let self else { return }
                        guard let applied = self.appliedEndpoints,
                              applied.from.latitude == from.latitude,
                              applied.from.longitude == from.longitude,
                              applied.to.latitude == to.latitude,
                              applied.to.longitude == to.longitude else { return }
                        self.replaceOverlay(on: map, with: polyline)
                    }
                } catch {
                    // Keep the geodesic fallback as-is.
                }
            }
        }

        private func replaceOverlay(on map: MKMapView, with polyline: MKPolyline) {
            if let active = activeOverlay { map.removeOverlay(active) }
            map.addOverlay(polyline, level: .aboveRoads)
            activeOverlay = polyline
            samples = PolylineSamples(polyline: polyline)
            didFitRoute = false
            fitRoute(map, animated: true)
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let line = overlay as? MKPolyline else {
                return MKOverlayRenderer(overlay: overlay)
            }
            let renderer = MKPolylineRenderer(polyline: line)
            renderer.strokeColor = UIColor.white
            renderer.lineWidth = 4
            renderer.lineCap = .round
            renderer.lineJoin = .round
            renderer.lineDashPattern = nil
            return renderer
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is TrainAnnotation {
                let id = "train"
                let view = mapView.dequeueReusableAnnotationView(withIdentifier: id) as? TrainAnnotationView
                    ?? TrainAnnotationView(annotation: annotation, reuseIdentifier: id)
                view.annotation = annotation
                view.applyBearing(currentBearing)
                return view
            }
            if let endpoint = annotation as? EndpointAnnotation {
                let id = "endpoint"
                let view = mapView.dequeueReusableAnnotationView(withIdentifier: id)
                    ?? MKAnnotationView(annotation: annotation, reuseIdentifier: id)
                view.annotation = annotation
                view.image = EndpointAnnotationView.dot(filled: endpoint.kind == .destination)
                view.centerOffset = .zero
                return view
            }
            return nil
        }
    }
}

// MARK: - Annotations

final class TrainAnnotation: NSObject, MKAnnotation {
    @objc dynamic var coordinate = CLLocationCoordinate2D()
}

final class EndpointAnnotation: NSObject, MKAnnotation {
    enum Kind { case origin, destination }
    @objc dynamic var coordinate = CLLocationCoordinate2D()
    var kind: Kind = .origin
}

/// A glowing tram glyph in a dark capsule. Rotates to point down the current
/// segment of the road polyline.
final class TrainAnnotationView: MKAnnotationView {
    private let body = UIView()

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        centerOffset = .zero

        body.frame = bounds
        body.backgroundColor = UIColor(white: 0.06, alpha: 0.95)
        body.layer.cornerRadius = 20
        body.layer.borderWidth = 2
        body.layer.borderColor = UIColor.white.cgColor
        body.layer.shadowColor = UIColor.white.cgColor
        body.layer.shadowOpacity = 0.9
        body.layer.shadowRadius = 10
        body.layer.shadowOffset = .zero
        body.isUserInteractionEnabled = false

        let symbol = UIImageView(frame: body.bounds.insetBy(dx: 10, dy: 10))
        symbol.contentMode = .scaleAspectFit
        symbol.tintColor = .white
        symbol.image = UIImage(systemName: "tram.fill")
        body.addSubview(symbol)

        addSubview(body)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// Rotate the train body to face `bearing` (degrees, 0 = north). Smooth
    /// over short durations so curves don't snap.
    func applyBearing(_ bearing: CLLocationDirection) {
        let radians = bearing * .pi / 180
        UIView.animate(withDuration: 0.5) {
            self.body.transform = CGAffineTransform(rotationAngle: radians)
        }
    }
}

/// Small endpoint markers (origin = hollow, destination = filled).
enum EndpointAnnotationView {
    static func dot(filled: Bool) -> UIImage {
        let size = CGSize(width: 14, height: 14)
        return UIGraphicsImageRenderer(size: size).image { ctx in
            let rect = CGRect(origin: .zero, size: size).insetBy(dx: 2, dy: 2)
            let path = UIBezierPath(ovalIn: rect)
            UIColor.white.setStroke()
            path.lineWidth = 2
            if filled {
                UIColor.white.setFill()
                path.fill()
            } else {
                UIColor(white: 0.06, alpha: 0.9).setFill()
                path.fill()
            }
            path.stroke()
        }
    }
}
