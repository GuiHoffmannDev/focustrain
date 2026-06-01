import SwiftUI
import MapKit

/// The live-session map: a geodesic route between the two cities with a glowing
/// train annotation that advances with `fraction`. The camera ease-follows the
/// train when `follow` is true, otherwise it frames the whole route.
struct RouteMapView: UIViewRepresentable {
    let from: CLLocationCoordinate2D
    let to: CLLocationCoordinate2D
    let fraction: Double
    let style: MapStyle
    let showLabels: Bool
    let follow: Bool

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.preferredConfiguration = style.mapConfiguration(showLabels: showLabels)
        map.isRotateEnabled = false
        map.isPitchEnabled = false
        map.showsCompass = false
        map.pointOfInterestFilter = showLabels ? .includingAll : .excludingAll

        // Route overlay.
        let polyline = MKGeodesicPolyline(coordinates: [from, to], count: 2)
        map.addOverlay(polyline, level: .aboveRoads)
        context.coordinator.polyline = polyline

        // Train annotation.
        let train = TrainAnnotation()
        train.coordinate = GreatCircle.interpolate(from: from, to: to, fraction: fraction)
        map.addAnnotation(train)
        context.coordinator.train = train

        // Endpoint dots.
        let origin = EndpointAnnotation(); origin.coordinate = from; origin.kind = .origin
        let dest = EndpointAnnotation(); dest.coordinate = to; dest.kind = .destination
        map.addAnnotations([origin, dest])

        context.coordinator.fitRoute(map, from: from, to: to, animated: false)
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

        // Advance the train smoothly.
        let target = GreatCircle.interpolate(from: from, to: to, fraction: fraction)
        if let train = coord.train {
            UIView.animate(withDuration: 0.5) {
                train.coordinate = target
            }
        }

        // Camera behaviour.
        if follow {
            let bearing = GreatCircle.bearing(from: from, to: to)
            let camera = MKMapCamera(
                lookingAtCenter: target,
                fromDistance: 1_400_000,
                pitch: 0,
                heading: bearing
            )
            map.setCamera(camera, animated: true)
            coord.didFitRoute = false
        } else if !coord.didFitRoute {
            coord.fitRoute(map, from: from, to: to, animated: true)
            coord.didFitRoute = true
        }
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, MKMapViewDelegate {
        var polyline: MKGeodesicPolyline?
        var train: TrainAnnotation?
        var appliedStyle: MapStyle?
        var appliedLabels: Bool?
        var didFitRoute = false

        func fitRoute(_ map: MKMapView, from: CLLocationCoordinate2D, to: CLLocationCoordinate2D, animated: Bool) {
            guard let polyline else { return }
            let inset = UIEdgeInsets(top: 120, left: 80, bottom: 200, right: 80)
            map.setVisibleMapRect(
                polyline.boundingMapRect,
                edgePadding: inset,
                animated: animated
            )
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

/// A glowing tram glyph in a dark capsule.
final class TrainAnnotationView: MKAnnotationView {
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        centerOffset = .zero

        let bg = UIView(frame: bounds)
        bg.backgroundColor = UIColor(white: 0.06, alpha: 0.95)
        bg.layer.cornerRadius = 20
        bg.layer.borderWidth = 2
        bg.layer.borderColor = UIColor.white.cgColor
        bg.layer.shadowColor = UIColor.white.cgColor
        bg.layer.shadowOpacity = 0.9
        bg.layer.shadowRadius = 10
        bg.layer.shadowOffset = .zero
        bg.isUserInteractionEnabled = false

        let symbol = UIImageView(frame: bg.bounds.insetBy(dx: 10, dy: 10))
        symbol.contentMode = .scaleAspectFit
        symbol.tintColor = .white
        symbol.image = UIImage(systemName: "tram.fill")
        bg.addSubview(symbol)

        addSubview(bg)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
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
