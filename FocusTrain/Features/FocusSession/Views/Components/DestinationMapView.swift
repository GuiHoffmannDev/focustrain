import SwiftUI
import MapKit

/// O picker de destino: um mapa 2D escuro com a origem do usuário, um anel
/// cosmético que cresce conforme a duração, e as 9 estações da ladder como pins
/// de trem que solidificam ao entrar no alcance. Tocar um pin seleciona a estação.
///
/// `DurationPickerModel.selectedIndex` é a única fonte de verdade; o anel e a
/// câmera são *sinks* — nunca escrevem de volta (sem loop de eco). O usuário pode
/// dar pan (2–3 dedos) e pinch-zoom para inspecionar as estações; a câmera só
/// reenquadra sozinha quando a seleção muda. Segue o padrão `UIViewRepresentable`
/// de `RouteMapView`/`GlobeHomeView` (UIKit disponível no Mac Catalyst, então sem
/// guards de plataforma).
struct DestinationMapView: UIViewRepresentable {
    let model: DurationPickerModel

    func makeCoordinator() -> Coordinator { Coordinator(model: model) }

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.preferredConfiguration = model.mapStyle.mapConfiguration(showLabels: model.mapShowLabels)
        context.coordinator.appliedStyle = model.mapStyle
        context.coordinator.appliedShowLabels = model.mapShowLabels
        map.isRotateEnabled = false
        map.isPitchEnabled = false
        map.isScrollEnabled = true   // pan para espiar as estações…
        map.isZoomEnabled = true     // …e pinch para zoom in/out
        map.showsCompass = false
        map.showsScale = false
        map.showsBuildings = false
        map.pointOfInterestFilter = .excludingAll
        map.overrideUserInterfaceStyle = .dark

        let origin = OriginAnnotation()
        origin.coordinate = model.origin.coordinate
        map.addAnnotation(origin)
        context.coordinator.origin = origin

        context.coordinator.syncStations(on: map)

        context.coordinator.applyRing(on: map)
        context.coordinator.reframe(map, animated: false)

        // Pan só com 2–3 dedos: 1 dedo continua selecionando pins e o mapa não
        // sai do lugar com toques incidentais. O pinch-zoom nativo segue valendo.
        context.coordinator.restrictPanToMultiTouch(on: map)
        let coordinator = context.coordinator
        DispatchQueue.main.async { coordinator.restrictPanToMultiTouch(on: map) }

        // Dessaturação do estilo monocromático: camada cinza em `saturationBlendMode`
        // que precisa ficar ENTRE os tiles e os pins. `mapView(_:didAdd:)` a
        // reposiciona abaixo das annotations sempre que elas entram, então o cinza
        // atinge só o mapa e a pill do destino segue colorida em qualquer estilo.
        let desat = UIView(frame: map.bounds)
        desat.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        desat.backgroundColor = UIColor(white: 0.5, alpha: 1)
        desat.layer.compositingFilter = "saturationBlendMode"
        desat.isUserInteractionEnabled = false
        desat.isHidden = model.mapStyle != .monochrome
        map.addSubview(desat)
        context.coordinator.desat = desat

        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        let coord = context.coordinator

        if coord.appliedStyle != model.mapStyle || coord.appliedShowLabels != model.mapShowLabels {
            map.preferredConfiguration = model.mapStyle.mapConfiguration(showLabels: model.mapShowLabels)
            coord.appliedStyle = model.mapStyle
            coord.appliedShowLabels = model.mapShowLabels
        }
        coord.desat?.isHidden = model.mapStyle != .monochrome

        // Origem resolvida pela CurrentCityResolver pode ter mudado.
        if let origin = coord.origin,
           origin.coordinate.latitude != model.origin.coordinate.latitude
            || origin.coordinate.longitude != model.origin.coordinate.longitude {
            origin.coordinate = model.origin.coordinate
        }

        // As destinations carregam de forma assíncrona (query SQLite) *depois* do
        // makeUIView, então os pins precisam ser (re)sincronizados aqui.
        coord.syncStations(on: map)
        coord.applyRing(on: map)

        for ann in coord.pins {
            guard let view = map.view(for: ann) as? StationAnnotationView else { continue }
            view.apply(state: coord.state(for: ann.index))
            coord.applyA11y(to: view, index: ann.index)
        }

        // A seleção visual é nossa, não a default do MapKit.
        for selected in map.selectedAnnotations {
            map.deselectAnnotation(selected, animated: false)
        }

        // Reenquadra no settle — nunca durante o arrasto da régua (evita jank).
        if model.interactionSource != .ruler {
            coord.reframe(map, animated: true)
        }
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, MKMapViewDelegate {
        let model: DurationPickerModel
        var pins: [StationAnnotation] = []
        private var appliedRoute: [String] = []
        var origin: OriginAnnotation?
        var desat: UIView?
        var ring: MKCircle?
        var appliedStyle: MapStyle?
        var appliedShowLabels: Bool?

        init(model: DurationPickerModel) { self.model = model }

        func state(for index: Int) -> StationAnnotationView.PinState {
            if index == model.selectedIndex { return .selected }
            if index < model.selectedIndex { return .solid }
            return .ghost
        }

        func applyA11y(to view: MKAnnotationView, index: Int) {
            let dest = model.destinations[index]
            let key = index == model.selectedIndex
                ? "durationPicker.station.a11ySelected"
                : "durationPicker.station.a11y"
            view.isAccessibilityElement = true
            view.accessibilityLabel = String(format: NSLocalizedString(key, comment: ""),
                                              dest.city, dest.minutes)
        }

        /// (Re)cria os pins quando `model.destinations` muda. A ladder carrega de
        /// forma assíncrona (query SQLite) *depois* que o `makeUIView` roda com a
        /// lista ainda vazia, então sem este sync o mapa fica sem pins mesmo com os
        /// cards já populados. Reconstrói só quando a rota muda de fato.
        func syncStations(on map: MKMapView) {
            let signature = model.destinations.map {
                "\($0.code)@\($0.station.coordinate.latitude),\($0.station.coordinate.longitude)"
            }
            guard signature != appliedRoute else { return }
            appliedRoute = signature
            map.removeAnnotations(pins)
            pins = model.destinations.enumerated().map { idx, dest in
                let a = StationAnnotation(index: idx, title: dest.city, code: dest.code)
                a.coordinate = dest.station.coordinate
                return a
            }
            map.addAnnotations(pins)
        }

        func applyRing(on map: MKMapView) {
            if let ring { map.removeOverlay(ring) }
            let circle = MKCircle(center: model.origin.coordinate, radius: model.ringRadiusMeters)
            map.addOverlay(circle, level: .aboveRoads)
            ring = circle
        }

        /// Enquadra origem + anel + pins sólidos (0...selectedIndex).
        func reframe(_ map: MKMapView, animated: Bool) {
            var rect = ring?.boundingMapRect ?? .null
            rect = rect.union(pointRect(model.origin.coordinate))
            for ann in pins where ann.index <= model.selectedIndex {
                rect = rect.union(pointRect(ann.coordinate))
            }
            guard !rect.isNull else { return }
            let inset = UIEdgeInsets(top: 120, left: 60, bottom: 320, right: 60)
            map.setVisibleMapRect(rect, edgePadding: inset, animated: animated)
        }

        private func pointRect(_ c: CLLocationCoordinate2D) -> MKMapRect {
            let p = MKMapPoint(c)
            return MKMapRect(x: p.x, y: p.y, width: 0, height: 0)
        }

        // MARK: Gestos

        /// Restringe o(s) pan recognizer(s) do próprio MKMapView a 2–3 dedos.
        /// Arrastos de 1 dedo deixam de mover o mapa (o tap segue selecionando os
        /// pins), enquanto 2 dedos fazem pan nativo — com momentum — e o pinch-zoom
        /// continua funcionando junto. Só API pública; se a internals da Apple mudar
        /// e nenhum recognizer for encontrado, o pan cai no padrão (ainda usável).
        func restrictPanToMultiTouch(on map: MKMapView) {
            for pan in Self.panRecognizers(in: map) {
                pan.minimumNumberOfTouches = 2
                pan.maximumNumberOfTouches = 3
            }
        }

        private static func panRecognizers(in view: UIView) -> [UIPanGestureRecognizer] {
            var found = (view.gestureRecognizers ?? []).compactMap { $0 as? UIPanGestureRecognizer }
            for sub in view.subviews { found += panRecognizers(in: sub) }
            return found
        }

        // MARK: MKMapViewDelegate

        func mapView(_ map: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let circle = overlay as? MKCircle else { return MKOverlayRenderer(overlay: overlay) }
            let r = MKCircleRenderer(circle: circle)
            r.strokeColor = UIColor.white.withAlphaComponent(0.5)
            r.lineWidth = 1.5
            r.fillColor = UIColor.white.withAlphaComponent(0.04)
            return r
        }

        func mapView(_ map: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is OriginAnnotation {
                let id = "origin"
                let v = map.dequeueReusableAnnotationView(withIdentifier: id)
                    ?? MKAnnotationView(annotation: annotation, reuseIdentifier: id)
                v.annotation = annotation
                v.image = OriginMarker.dot()
                v.centerOffset = .zero
                v.isAccessibilityElement = false
                return v
            }
            if let station = annotation as? StationAnnotation {
                let id = "station"
                let v = (map.dequeueReusableAnnotationView(withIdentifier: id) as? StationAnnotationView)
                    ?? StationAnnotationView(annotation: annotation, reuseIdentifier: id)
                v.annotation = annotation
                v.apply(state: state(for: station.index))
                applyA11y(to: v, index: station.index)
                return v
            }
            return nil
        }

        /// Mantém a camada de dessaturação logo abaixo das annotations (e acima
        /// dos tiles). Subviews adicionadas via `addSubview` ficam por cima dos
        /// pins, então reposicionamos a cada vez que o MapKit cria pins novos.
        func mapView(_ map: MKMapView, didAdd views: [MKAnnotationView]) {
            guard let desat else { return }
            if let firstAnnotation = map.subviews.first(where: { $0 is MKAnnotationView }) {
                map.insertSubview(desat, belowSubview: firstAnnotation)
            }
        }

        func mapView(_ map: MKMapView, didSelect view: MKAnnotationView) {
            guard let station = view.annotation as? StationAnnotation else { return }
            model.beginInteraction(.map)
            model.select(station.index, from: .map)
            model.endInteraction()
            if let ann = view.annotation { map.deselectAnnotation(ann, animated: false) }
        }
    }
}

// MARK: - Annotations

final class StationAnnotation: NSObject, MKAnnotation {
    let index: Int
    @objc dynamic var coordinate = CLLocationCoordinate2D()
    let title: String?
    let code: String
    init(index: Int, title: String, code: String) {
        self.index = index
        self.title = title
        self.code = code
        super.init()
    }
}

final class OriginAnnotation: NSObject, MKAnnotation {
    @objc dynamic var coordinate = CLLocationCoordinate2D()
}

// MARK: - Pin view

/// Pin de trem com três estados. Pulso via `CABasicAnimation` (só ≤ 9 pins).
final class StationAnnotationView: MKAnnotationView {
    enum PinState { case ghost, solid, selected }

    private let disc = UIView()
    private let glyph = UIImageView()
    private let pulse = CALayer()
    private var currentState: PinState?

    private static let brass = UIColor(red: 0xE0/255.0, green: 0xA4/255.0, blue: 0x58/255.0, alpha: 1)
    private static let pillFill = UIColor(white: 0.06, alpha: 1)
    private static let pillHeight: CGFloat = 30
    private static let pillCorner: CGFloat = 8
    private static let pillIconSize: CGFloat = 15
    private static let pillIconGap: CGFloat = 5
    private static let pillPadLead: CGFloat = 9
    private static let pillPadTrail: CGFloat = 11

    private let pill = UIView()
    private let pillIcon = UIImageView()
    private let pillLabel = UILabel()

    override var annotation: MKAnnotation? {
        didSet {
            guard let station = annotation as? StationAnnotation else { return }
            pillLabel.text = station.code
            if bounds.width > 0 { layoutPill() }
        }
    }

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        frame = CGRect(x: 0, y: 0, width: 36, height: 36)
        centerOffset = .zero
        canShowCallout = false

        pulse.frame = bounds
        pulse.cornerRadius = bounds.width / 2
        pulse.borderWidth = 2
        pulse.borderColor = UIColor.white.cgColor
        pulse.opacity = 0
        layer.addSublayer(pulse)

        disc.frame = bounds.insetBy(dx: 6, dy: 6)
        disc.backgroundColor = UIColor(white: 0.06, alpha: 0.95)
        disc.layer.cornerRadius = disc.bounds.width / 2
        disc.layer.borderWidth = 2
        disc.isUserInteractionEnabled = false
        addSubview(disc)

        glyph.frame = disc.bounds.insetBy(dx: 6, dy: 6)
        glyph.contentMode = .scaleAspectFit
        glyph.tintColor = .white
        glyph.image = UIImage(systemName: "tram.fill")
        disc.addSubview(glyph)

        // Pill do destino selecionado: transborda os bounds 36×36 (sem clipar),
        // então o disco segue sendo o tap-target. Começa oculta.
        clipsToBounds = false
        pill.backgroundColor = Self.pillFill
        pill.layer.cornerRadius = Self.pillCorner
        pill.layer.borderWidth = 2
        pill.layer.borderColor = Self.brass.cgColor
        pill.layer.shadowColor = Self.brass.cgColor
        pill.layer.shadowRadius = 8
        pill.layer.shadowOffset = .zero
        pill.layer.shadowOpacity = 0
        pill.isUserInteractionEnabled = false
        pill.isHidden = true
        addSubview(pill)

        pillIcon.image = UIImage(
            systemName: "tram.fill",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .bold)
        )
        pillIcon.tintColor = Self.brass
        pillIcon.contentMode = .scaleAspectFit
        pill.addSubview(pillIcon)

        pillLabel.font = .systemFont(ofSize: 13, weight: .heavy)
        pillLabel.textColor = Self.brass
        pillLabel.textAlignment = .left
        pill.addSubview(pillLabel)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// Dimensiona a pill ao conteúdo (ícone + código) e a centraliza sobre o
    /// ponto da estação. Larga para os lados a partir do centro dos bounds.
    private func layoutPill() {
        pillLabel.sizeToFit()
        let labelW = ceil(pillLabel.bounds.width)
        let w = Self.pillPadLead + Self.pillIconSize + Self.pillIconGap + labelW + Self.pillPadTrail
        let h = Self.pillHeight
        pill.bounds = CGRect(x: 0, y: 0, width: w, height: h)
        pill.center = CGPoint(x: bounds.midX, y: bounds.midY)
        pillIcon.frame = CGRect(x: Self.pillPadLead,
                                y: (h - Self.pillIconSize) / 2,
                                width: Self.pillIconSize, height: Self.pillIconSize)
        pillLabel.frame = CGRect(x: Self.pillPadLead + Self.pillIconSize + Self.pillIconGap,
                                 y: 0, width: labelW, height: h)
    }

    func apply(state: PinState) {
        guard state != currentState else { return }
        currentState = state
        switch state {
        case .ghost:
            pill.isHidden = true
            disc.isHidden = false
            alpha = 0.3
            transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
            disc.layer.borderColor = UIColor.white.withAlphaComponent(0.4).cgColor
            disc.layer.shadowOpacity = 0
            stopPulse()
        case .solid:
            pill.isHidden = true
            disc.isHidden = false
            alpha = 1.0
            transform = .identity
            disc.layer.borderColor = UIColor.white.cgColor
            disc.layer.shadowOpacity = 0
            startPulse(color: .white, capsule: false)
        case .selected:
            disc.isHidden = true
            pill.isHidden = false
            alpha = 1.0
            transform = .identity
            layoutPill()
            pill.layer.shadowOpacity = 0.85
            startPulse(color: Self.brass, capsule: true)
            // Leve "expandir" pra dar vida à troca de destino.
            pill.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
            UIView.animate(withDuration: 0.18, delay: 0,
                           options: [.curveEaseOut, .allowUserInteraction, .beginFromCurrentState]) {
                self.pill.transform = .identity
            }
        }
    }

    private func startPulse(color: UIColor, capsule: Bool) {
        if capsule {
            pulse.frame = pill.frame
            pulse.cornerRadius = Self.pillCorner
        } else {
            pulse.frame = bounds
            pulse.cornerRadius = bounds.width / 2
        }
        pulse.borderColor = color.cgColor
        // Restart so the running cycle picks up the new geometry/color.
        pulse.removeAnimation(forKey: "pulse")
        let scale = CABasicAnimation(keyPath: "transform.scale")
        scale.fromValue = 1.0
        scale.toValue = 1.3
        let fade = CABasicAnimation(keyPath: "opacity")
        fade.fromValue = 0.6
        fade.toValue = 0.0
        let group = CAAnimationGroup()
        group.animations = [scale, fade]
        group.duration = 2.0
        group.repeatCount = .infinity
        group.timingFunction = CAMediaTimingFunction(name: .easeOut)
        pulse.add(group, forKey: "pulse")
    }

    private func stopPulse() {
        pulse.removeAnimation(forKey: "pulse")
        pulse.opacity = 0
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        currentState = nil
        stopPulse()
        transform = .identity
        pill.transform = .identity
        pill.isHidden = true
        disc.isHidden = false
        pill.layer.shadowOpacity = 0
    }
}

// MARK: - Origin marker

enum OriginMarker {
    static func dot() -> UIImage {
        let size = CGSize(width: 16, height: 16)
        return UIGraphicsImageRenderer(size: size).image { _ in
            let rect = CGRect(origin: .zero, size: size).insetBy(dx: 2, dy: 2)
            let path = UIBezierPath(ovalIn: rect)
            UIColor.white.setFill()
            path.fill()
        }
    }
}

#if DEBUG
#Preview("DestinationMap") {
    let m = DurationPickerModel(haptics: NoopDetentService())
    m.select(4, from: .ruler)   // alcance médio: 5 sólidos, 4 fantasmas
    return ZStack {
        FT.Palette.black.ignoresSafeArea()
        DestinationMapView(model: m).ignoresSafeArea()
    }
}
#endif
