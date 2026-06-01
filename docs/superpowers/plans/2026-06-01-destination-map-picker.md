# Destination Map Picker Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Substituir a superfície radar/carrossel do `DurationPickerView` por um mapa MapKit 2D escuro com anel cosmético e pins de trem que solidificam conforme a régua de tempo cresce o alcance.

**Architecture:** `DurationPickerModel.selectedIndex` (ladder curada de 9 paradas) continua a única fonte de verdade. Um `MKMapView` via `UIViewRepresentable` (`DestinationMapView`, padrão de `RouteMapView`) renderiza origem + `MKCircle` cosmético + 9 `StationAnnotation`. Régua e tap-no-pin escrevem em `selectedIndex` via `select(_:from:)`; anel e câmera são *sinks* puros (sem loop de eco). Reframe da câmera só no settle da seleção.

**Tech Stack:** SwiftUI, MapKit (`MKMapView`/`MKCircle`/`MKAnnotationView`), Core Animation (`CABasicAnimation` para pulso), Core Haptics (via `DetentHapticsService` existente). iOS 17+ / Mac Catalyst (UIKit disponível — sem guards de plataforma, como `RouteMapView`).

**Convenções do repo (invioláveis):**
- Nunca editar `.pbxproj`. Arquivos novos são dropados nas pastas synced; basta criar/deletar o `.swift`.
- Cópia user-facing via `NSLocalizedString` sobre `Localizable.xcstrings` (source `en` + `pt-BR`).
- Accent branco (`FT.Palette.brandRail`); brass `#E0A458` (`FT.Palette.brandBrass`) é o calor secundário.
- Não há test target XCTest. O padrão de teste do repo é **`#Preview` self-check** (lógica) + **build/manual** (views). Este plano segue esse padrão.
- Verificar a cada task: `xcodebuild -scheme FocusTrain -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build` → `** BUILD SUCCEEDED **`.

**Spec:** `docs/superpowers/specs/2026-06-01-destination-map-picker-design.md`

---

## File Structure

| Arquivo | Responsabilidade | Ação |
|---|---|---|
| `FocusTrain/Features/FocusSession/ViewModels/DurationPickerModel.swift` | Fonte de verdade + derivados (`reachableCount`, `ringRadiusMeters`); `InteractionSource` (`none/ruler/map`) | Modificar |
| `FocusTrain/Features/FocusSession/Views/DurationPickerView.swift` | Layout map-cêntrico (mapa + título overlay + régua/chips/CTA) | Modificar |
| `FocusTrain/Features/FocusSession/Views/Components/DestinationMapView.swift` | `MKMapView` representable + Coordinator + anel + annotations + pin view | Criar |
| `FocusTrain/Features/FocusSession/Views/Components/RadarDialView.swift` | (radar) | **Deletar** |
| `FocusTrain/Features/FocusSession/Views/Components/DestinationCarouselView.swift` | (carrossel) | **Deletar** |
| `FocusTrain/Features/FocusSession/Views/Components/DestinationPin.swift` | (pin do radar) | **Deletar** |
| `FocusTrain/Features/FocusSession/Views/Components/DestinationCard.swift` | (card do carrossel) | **Deletar** |
| `FocusTrain/Resources/Localizable.xcstrings` | Chaves a11y dos pins | Modificar |

`StationAnnotation`, `OriginAnnotation`, `StationAnnotationView`, `OriginMarker` vivem **dentro de `DestinationMapView.swift`** (espelha `RouteMapView.swift`, que mantém suas annotations no mesmo arquivo).

---

## Task 1: Retirar radar/carrossel e renomear `InteractionSource`

Mantém o build verde e o fluxo funcional (régua + chips + CTA), sem o mapa ainda.

**Files:**
- Delete: `FocusTrain/Features/FocusSession/Views/Components/RadarDialView.swift`
- Delete: `FocusTrain/Features/FocusSession/Views/Components/DestinationCarouselView.swift`
- Delete: `FocusTrain/Features/FocusSession/Views/Components/DestinationPin.swift`
- Delete: `FocusTrain/Features/FocusSession/Views/Components/DestinationCard.swift`
- Modify: `FocusTrain/Features/FocusSession/ViewModels/DurationPickerModel.swift`
- Modify: `FocusTrain/Features/FocusSession/Views/DurationPickerView.swift`

- [ ] **Step 1: Deletar os 4 componentes retirados**

```bash
rm FocusTrain/Features/FocusSession/Views/Components/RadarDialView.swift \
   FocusTrain/Features/FocusSession/Views/Components/DestinationCarouselView.swift \
   FocusTrain/Features/FocusSession/Views/Components/DestinationPin.swift \
   FocusTrain/Features/FocusSession/Views/Components/DestinationCard.swift
```

- [ ] **Step 2: Renomear `InteractionSource` no model**

Em `DurationPickerModel.swift`, trocar o enum (remove `.radar`, `.carousel`; adiciona `.map`):

```swift
enum InteractionSource: Equatable { case none, ruler, map }
```

No `#Preview "DurationPickerModel self-check"`, a linha que usa `.radar`/`.carousel` deixa de compilar. Trocar:

```swift
// dedup: selecting the same index twice keeps it put
m.select(3, from: .map); let after = m.selectedIndex; m.select(3, from: .ruler)
let dedup = m.selectedIndex == after && after == 3
```

- [ ] **Step 3: Remover usos de radar/carrossel do `DurationPickerView`**

Em `DurationPickerView.swift`, deletar o bloco do radar:

```swift
                    RadarDialView(model: model)
                        .opacity(appeared ? 1 : 0).scaleEffect(appeared ? 1 : 0.96)

```

e o bloco do carrossel:

```swift
                    DestinationCarouselView(model: model)
                        .opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 18)

```

(O resto do corpo — título, label de minutos, `TimeRulerView`, `ScenarioChips`, `CTAButton` — permanece. Será reescrito por completo na Task 4.)

- [ ] **Step 4: Confirmar que nada mais referencia os tipos deletados**

Run:
```bash
grep -rn "RadarDialView\|DestinationCarouselView\|DestinationPin\|DestinationCard\|\.radar\|\.carousel" FocusTrain --include="*.swift"
```
Expected: nenhuma saída (zero referências restantes).

- [ ] **Step 5: Build**

Run:
```bash
xcodebuild -scheme FocusTrain -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 6: Commit**

```bash
git add -A FocusTrain/Features/FocusSession
git commit -m "refactor: retire radar/carousel picker surface; ruler-only interim

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 2: Estado derivado no model (`reachableCount`, `ringRadiusMeters`)

TDD via build: o self-check referencia as novas props antes de existirem → build falha (red) → implementa → build passa (green).

**Files:**
- Modify: `FocusTrain/Features/FocusSession/ViewModels/DurationPickerModel.swift`

- [ ] **Step 1: Escrever as asserções no self-check (red)**

No `#Preview "DurationPickerModel self-check"`, logo após a linha `m.select(-5, from: .ruler);  let clampLo = ...`, inserir:

```swift
    let reach0 = m.reachableCount == 1            // index 0 → 1 estação em alcance
    let ring0  = m.ringRadiusMeters               // raio na estação mais curta
```

E logo após `let t = m.makeTicket()` (já em index do 90min), inserir:

```swift
    let reachAll = m.reachableCount == m.destinations.count
    let ringGrew = m.ringRadiusMeters > ring0 && m.ringRadiusMeters > 0
```

E ampliar a linha `let pass = ...`:

```swift
    let pass = clampHi && clampLo && dedup && ticketOK && reach0 && reachAll && ringGrew
```

- [ ] **Step 2: Build para confirmar a falha (red)**

Run:
```bash
xcodebuild -scheme FocusTrain -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```
Expected: FAIL — `value of type 'DurationPickerModel' has no member 'reachableCount'` / `ringRadiusMeters`.

- [ ] **Step 3: Implementar os derivados (green)**

Em `DurationPickerModel.swift`, dentro da classe, após `var selectedDestination: Destination { destinations[selectedIndex] }`, adicionar:

```swift
    // MARK: - Estado derivado (sinks read-only; selectedIndex é a única fonte)

    /// Estações "em alcance" (sólidas): índices 0...selectedIndex inclusive.
    var reachableCount: Int { selectedIndex + 1 }

    /// Raio cosmético do anel no mapa, em metros — estilizado a partir do
    /// nominalKm da estação selecionada (não é distância geográfica real).
    var ringRadiusMeters: CLLocationDistance {
        Double(selectedDestination.nominalKm) * 1_000 * Self.ringScale
    }

    /// Multiplicador visual do anel (tunável).
    static let ringScale: Double = 1.0
```

(`CLLocationDistance` já disponível: o arquivo importa `CoreLocation`.)

- [ ] **Step 4: Build (green)**

Run:
```bash
xcodebuild -scheme FocusTrain -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```
Expected: `** BUILD SUCCEEDED **`. (Abrir o preview "DurationPickerModel self-check" no Xcode deve mostrar `PASS ✓`.)

- [ ] **Step 5: Commit**

```bash
git add FocusTrain/Features/FocusSession/ViewModels/DurationPickerModel.swift
git commit -m "feat: DurationPickerModel reachableCount + ringRadiusMeters derived state

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 3: `DestinationMapView` (mapa + anel + pins)

Arquivo único com representable + Coordinator + annotations + pin view, espelhando `RouteMapView.swift`.

**Files:**
- Create: `FocusTrain/Features/FocusSession/Views/Components/DestinationMapView.swift`

- [ ] **Step 1: Criar o arquivo completo**

```swift
import SwiftUI
import MapKit

/// O picker de destino: um mapa 2D escuro com a origem do usuário, um anel
/// cosmético que cresce conforme a duração, e as 9 estações da ladder como pins
/// de trem que solidificam ao entrar no alcance. Tocar um pin seleciona a estação.
///
/// `DurationPickerModel.selectedIndex` é a única fonte de verdade; o anel e a
/// câmera são *sinks* — nunca escrevem de volta (sem loop de eco). Segue o padrão
/// `UIViewRepresentable` de `RouteMapView`/`GlobeHomeView` (UIKit disponível no
/// Mac Catalyst, então sem guards de plataforma).
struct DestinationMapView: UIViewRepresentable {
    let model: DurationPickerModel

    func makeCoordinator() -> Coordinator { Coordinator(model: model) }

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.preferredConfiguration = model.mapStyle.mapConfiguration(showLabels: false)
        map.isRotateEnabled = false
        map.isPitchEnabled = false
        map.isScrollEnabled = false
        map.isZoomEnabled = false
        map.showsCompass = false
        map.showsScale = false
        map.showsBuildings = false
        map.pointOfInterestFilter = .excludingAll
        map.overrideUserInterfaceStyle = .dark

        let origin = OriginAnnotation()
        origin.coordinate = model.origin.coordinate
        map.addAnnotation(origin)
        context.coordinator.origin = origin

        var pins: [StationAnnotation] = []
        for (idx, dest) in model.destinations.enumerated() {
            let a = StationAnnotation(index: idx, title: dest.city)
            a.coordinate = dest.station.coordinate
            pins.append(a)
        }
        map.addAnnotations(pins)
        context.coordinator.pins = pins

        context.coordinator.applyRing(on: map)
        context.coordinator.reframe(map, animated: false)
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        let coord = context.coordinator

        if coord.appliedStyle != model.mapStyle {
            map.preferredConfiguration = model.mapStyle.mapConfiguration(showLabels: false)
            coord.appliedStyle = model.mapStyle
        }

        // Origem resolvida pela CurrentCityResolver pode ter mudado.
        if let origin = coord.origin,
           origin.coordinate.latitude != model.origin.coordinate.latitude
            || origin.coordinate.longitude != model.origin.coordinate.longitude {
            origin.coordinate = model.origin.coordinate
        }

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
        var origin: OriginAnnotation?
        var ring: MKCircle?
        var appliedStyle: MapStyle?

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
    init(index: Int, title: String) {
        self.index = index
        self.title = title
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
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func apply(state: PinState) {
        guard state != currentState else { return }
        currentState = state
        switch state {
        case .ghost:
            alpha = 0.3
            transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
            disc.layer.borderColor = UIColor.white.withAlphaComponent(0.4).cgColor
            disc.layer.shadowOpacity = 0
            stopPulse()
        case .solid:
            alpha = 1.0
            transform = .identity
            disc.layer.borderColor = UIColor.white.cgColor
            disc.layer.shadowOpacity = 0
            startPulse(color: .white)
        case .selected:
            alpha = 1.0
            transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
            disc.layer.borderColor = Self.brass.cgColor
            disc.layer.shadowColor = Self.brass.cgColor
            disc.layer.shadowRadius = 8
            disc.layer.shadowOffset = .zero
            disc.layer.shadowOpacity = 0.8
            startPulse(color: Self.brass)
        }
    }

    private func startPulse(color: UIColor) {
        pulse.borderColor = color.cgColor
        guard pulse.animation(forKey: "pulse") == nil else { return }
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
```

> Nota: as chaves `durationPicker.station.a11y[/Selected]` usadas em `applyA11y`
> só são adicionadas na Task 5. `NSLocalizedString` com chave ausente compila e
> retorna a própria chave em runtime — então o build da Task 3 passa; o texto a11y
> fica "cru" até a Task 5. Sem dependência de compilação.

- [ ] **Step 2: Build**

Run:
```bash
xcodebuild -scheme FocusTrain -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```
Expected: `** BUILD SUCCEEDED **`. (Abrir o preview "DestinationMap" no Xcode: origem branca, anel, 5 pins sólidos pulsando, 4 fantasmas; o de index 4 com borda brass.)

- [ ] **Step 3: Commit**

```bash
git add FocusTrain/Features/FocusSession/Views/Components/DestinationMapView.swift
git commit -m "feat: DestinationMapView (dark map + cosmetic ring + train pins)

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 4: Layout map-cêntrico no `DurationPickerView`

**Files:**
- Modify: `FocusTrain/Features/FocusSession/Views/DurationPickerView.swift`

- [ ] **Step 1: Substituir o `body` por completo**

Trocar todo o corpo da `struct DurationPickerView` (do `var body: some View {` até o fechamento `}` antes do fim da struct) por:

```swift
    var body: some View {
        ZStack {
            FT.Palette.black.ignoresSafeArea()

            DestinationMapView(model: model)
                .ignoresSafeArea()
                .opacity(appeared ? 1 : 0)

            // Scrim topo (título) + base (controles) para legibilidade.
            VStack {
                LinearGradient(colors: [FT.Palette.black.opacity(0.6), .clear],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: 180)
                Spacer()
                LinearGradient(colors: [.clear, FT.Palette.black.opacity(0.85), FT.Palette.black],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: 360)
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            // Título sobre o mapa.
            VStack(alignment: .leading, spacing: 0) {
                Text(NSLocalizedString("durationPicker.title", comment: ""))
                    .font(FT.Typography.sectionTitle)
                    .foregroundStyle(FT.Palette.white)
                    .padding(.horizontal, FT.Layout.sideMargin)
                    .padding(.top, 8)
                    .opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 12)
                Spacer()
            }

            // Controles fixos embaixo.
            VStack {
                Spacer()
                VStack(spacing: 16) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(model.selectedDestination.minutes)")
                            .font(.system(size: 44, weight: .heavy))
                            .contentTransition(.numericText())
                        Text(NSLocalizedString("durationPicker.minutes", comment: ""))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(FT.Palette.textSecondary)
                    }
                    .foregroundStyle(FT.Palette.white)
                    .animation(.spring(response: 0.4, dampingFraction: 0.85), value: model.selectedIndex)

                    TimeRulerView(model: model)

                    ScenarioChips(selection: Binding(
                        get: { model.scenario },
                        set: { model.scenario = $0 }
                    ))
                    .padding(.horizontal, FT.Layout.sideMargin)

                    CTAButton(title: NSLocalizedString("compose.depart", comment: ""),
                              style: .primary, icon: "arrow.right",
                              action: { onDepart(model.makeTicket()) })
                        .padding(.horizontal, FT.Layout.sideMargin)
                }
                .padding(.bottom, 12)
                .opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 24)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(FT.Palette.white)
                }
            }
        }
        .onAppear {
            model.prepareHaptics()
            resolver.bootstrap()
            guard !appeared else { return }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) { appeared = true }
        }
        .onChange(of: resolver.cityName) { _, name in
            if let name, let coord = resolver.coordinate {
                model.setOrigin(city: name, coordinate: coord)
            }
        }
    }
```

> O `body` lê `model.selectedDestination.minutes` (label), então qualquer mudança
> de `selectedIndex` re-renderiza a `DurationPickerView` e dispara
> `DestinationMapView.updateUIView` — é o que mantém anel/pins/câmera em sync.

- [ ] **Step 2: Build**

Run:
```bash
xcodebuild -scheme FocusTrain -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Rodar e verificar a interação (manual)**

Run:
```bash
xcodebuild -scheme FocusTrain -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
xcrun simctl boot "iPhone 17 Pro" 2>/dev/null; open -a Simulator
```
Navegar até o picker e conferir o checklist:
- Arrastar a régua → anel cresce, pins fantasmas solidificam/pulsam, **câmera fica parada** durante o arrasto.
- Soltar a régua → câmera reenquadra suavemente para caber origem + anel + sólidos.
- Tocar um pin sólido → seleciona (borda brass), câmera reenquadra, **um** tick háptico.
- Tocar o mesmo pin de novo → sem novo tick (dedup).
- "Embarcar" → avança (o `Ticket` carrega a cidade/minutos selecionados).

- [ ] **Step 4: Commit**

```bash
git add FocusTrain/Features/FocusSession/Views/DurationPickerView.swift
git commit -m "feat: map-centric DurationPickerView layout

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 5: Chaves de localização a11y dos pins

**Files:**
- Modify: `FocusTrain/Resources/Localizable.xcstrings`

- [ ] **Step 1: Revisar diff pendente do catálogo (evitar bundle indevido)**

O catálogo já tem alterações não-commitadas (pré-existentes a este trabalho). Antes de editar, inspecionar:

Run:
```bash
git diff FocusTrain/Resources/Localizable.xcstrings
```
Expected: ver +15 linhas pré-existentes (chaves `durationPicker.*` do trabalho anterior). Confirmar que são intencionais antes de prosseguir; se houver dúvida, perguntar ao usuário.

- [ ] **Step 2: Adicionar as duas chaves**

No objeto top-level `"strings"` de `Localizable.xcstrings`, adicionar (formato idêntico aos vizinhos `durationPicker.*`):

```json
    "durationPicker.station.a11y" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "%1$@, %2$d min" } },
        "pt-BR" : { "stringUnit" : { "state" : "translated", "value" : "%1$@, %2$d minutos" } }
      }
    },
    "durationPicker.station.a11ySelected" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "%1$@, %2$d min, selected" } },
        "pt-BR" : { "stringUnit" : { "state" : "translated", "value" : "%1$@, %2$d minutos, selecionada" } }
      }
    },
```

- [ ] **Step 3: Validar que o JSON continua válido**

Run:
```bash
python3 -c "import json; d=json.load(open('FocusTrain/Resources/Localizable.xcstrings')); assert 'durationPicker.station.a11y' in d['strings'] and 'durationPicker.station.a11ySelected' in d['strings']; print('OK', len(d['strings']), 'keys')"
```
Expected: `OK 203 keys`

- [ ] **Step 4: Build e conferir VoiceOver (manual)**

Run:
```bash
xcodebuild -scheme FocusTrain -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```
Expected: `** BUILD SUCCEEDED **`. Com VoiceOver no simulador, focar um pin lê "Tóquio, 90 minutos[, selecionada]".

- [ ] **Step 5: Commit**

```bash
git add FocusTrain/Resources/Localizable.xcstrings
git commit -m "feat: a11y labels for destination station pins

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 6: Verificação final e limpeza

**Files:** (nenhum novo — auditoria)

- [ ] **Step 1: Confirmar zero referências a tipos removidos**

Run:
```bash
grep -rn "RadarDialView\|DestinationCarouselView\|DestinationPin\|DestinationCard\|\.radar\b\|\.carousel\b" FocusTrain --include="*.swift"
```
Expected: nenhuma saída.

- [ ] **Step 2: Build limpo final**

Run:
```bash
xcodebuild -scheme FocusTrain -destination 'platform=iOS Simulator,name=iPhone 17 Pro' clean build
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Checklist de UX final (manual, simulador)**

Conferir os 4 fluxos e o macOS (Catalyst, se disponível):
- iOS: régua cresce anel + revela pins; settle reenquadra; tap seleciona + tick; Embarcar gera Ticket correto.
- macOS/Catalyst: sem háptico (Noop); tap no pin e arrasto da régua funcionam; reframe anima.
- Offline (desligar rede do simulador): mapa fica escuro, mas anel/pins/régua/seleção/Embarcar continuam funcionando.

- [ ] **Step 4: Confirmar histórico de commits**

Run:
```bash
git log --oneline -6
```
Expected: ver os commits das Tasks 1–5 na ordem.

---

## Notas de risco / atenção

- **Sync via re-render do parent:** `updateUIView` só roda quando a `DurationPickerView` re-renderiza. O `body` lê `model.selectedDestination.minutes`, garantindo o trigger em toda mudança de `selectedIndex`. Não remover essa leitura.
- **Câmera durante arrasto:** o gate `if model.interactionSource != .ruler` evita reframes a cada tick. `TimeRulerView` chama `beginInteraction(.ruler)`/`endInteraction()` — o `endInteraction` (→ `.none`) dispara o re-render final que reenquadra.
- **`transform` em `MKAnnotationView`:** usado para escala estática dos estados; se o MapKit resetar o transform em algum layout, trocar por ajuste de `frame`/`bounds`. Validar visualmente na Task 3.
- **`f()` do anel (`ringScale`):** se o anel ficar grande/pequeno demais no zoom mundial, ajustar `DurationPickerModel.ringScale` (constante única).
- **Catálogo de strings:** tem diff pré-existente — sempre revisar `git diff` antes de `git add` para não commitar mudanças alheias.
