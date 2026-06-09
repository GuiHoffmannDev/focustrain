# Badge de código no destino selecionado — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** No picker de duração, exibir o destino *selecionado* como uma pill em accent (ícone `tram.fill` + código de 3 letras) centrada sobre a estação, como confirmação visual de "para onde estou indo".

**Architecture:** Mudança aditiva num único arquivo, `DestinationMapView.swift`. A annotation ganha o código; a `StationAnnotationView` ganha uma segunda forma (pill) que sobrepõe o disco e aparece só no estado `.selected`. O disco de 36×36 continua sendo o tap-target (a pill transborda os bounds sem clipar), então a seleção por toque não muda. Ghost/solid ficam idênticos.

**Tech Stack:** Swift, UIKit, MapKit (`MKAnnotationView` dentro de um `UIViewRepresentable`). Mac Catalyst disponível, sem guards de plataforma. Sem target de teste UIKit no projeto.

> **Nota sobre testes:** este projeto não tem target de teste do Xcode; o harness SwiftPM (`Tests/CitiesHarness`) cobre só a lógica de dados das Cities. A mudança aqui é 100% de renderização UIKit/MapKit, sem costura de lógica nova para unit-test (o código já vem pronto de `Station.code`). A verificação é por **compilação para o simulador** + **checagem visual no `#Preview` existente**. Isso é coerente com o harness atual do projeto.

---

## File Structure

- **Modify:** `FocusTrain/Features/FocusSession/Views/Components/DestinationMapView.swift`
  - `StationAnnotation` (classe no fim do arquivo): novo campo `code`.
  - `DestinationMapView.makeUIView`: passar `dest.code` ao criar a annotation.
  - `StationAnnotationView`: subviews da pill, layout dinâmico, morph disco↔pill em `apply(state:)`, pulse adaptado a cápsula.

Nenhum arquivo novo. Nenhuma mudança de modelo de dados além do campo na annotation.

---

### Task 1: Levar o código da cidade até a annotation

**Files:**
- Modify: `FocusTrain/Features/FocusSession/Views/Components/DestinationMapView.swift`

- [ ] **Step 1: Adicionar o campo `code` à `StationAnnotation`**

Substituir a classe `StationAnnotation` (perto do fim do arquivo) por:

```swift
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
```

- [ ] **Step 2: Passar `dest.code` ao criar os pins em `makeUIView`**

Em `makeUIView`, dentro do loop `for (idx, dest) in model.destinations.enumerated()`, trocar:

```swift
let a = StationAnnotation(index: idx, title: dest.city)
```

por:

```swift
let a = StationAnnotation(index: idx, title: dest.city, code: dest.code)
```

- [ ] **Step 3: Compilar para o simulador (verificar que ainda compila)**

Run:
```bash
xcodebuild -project FocusTrain.xcodeproj -scheme FocusTrain \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -configuration Debug CODE_SIGNING_ALLOWED=NO build
```
Expected: `** BUILD SUCCEEDED **`. (Sem mudança visual ainda — `code` ainda não é usado.)

- [ ] **Step 4: Commit**

```bash
git add FocusTrain/Features/FocusSession/Views/Components/DestinationMapView.swift
git commit -m "feat(picker): carry city code into StationAnnotation"
```

---

### Task 2: Adicionar as subviews da pill (ocultas, sem mudança de comportamento)

**Files:**
- Modify: `FocusTrain/Features/FocusSession/Views/Components/DestinationMapView.swift` (classe `StationAnnotationView`)

Esta task só introduz a UI da pill e seu layout. A pill nasce `isHidden = true` e ainda não é referenciada em `apply(state:)`, então não há mudança visual.

- [ ] **Step 1: Declarar as constantes e subviews da pill**

No topo de `StationAnnotationView`, logo abaixo da linha existente
`private static let brass = UIColor(...)`, adicionar:

```swift
private static let pillInk = UIColor(white: 0.08, alpha: 1)
private static let pillHeight: CGFloat = 30
private static let pillIconSize: CGFloat = 15
private static let pillIconGap: CGFloat = 5
private static let pillPadLead: CGFloat = 9
private static let pillPadTrail: CGFloat = 11

private let pill = UIView()
private let pillIcon = UIImageView()
private let pillLabel = UILabel()
```

- [ ] **Step 2: Montar a pill no `init`**

No final do `init(annotation:reuseIdentifier:)`, logo após o bloco que adiciona o `glyph` ao `disc` (a última linha é `disc.addSubview(glyph)`), adicionar:

```swift
// Pill do destino selecionado: transborda os bounds 36×36 (sem clipar),
// então o disco segue sendo o tap-target. Começa oculta.
clipsToBounds = false
pill.backgroundColor = Self.brass
pill.layer.cornerRadius = Self.pillHeight / 2
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
pillIcon.tintColor = Self.pillInk
pillIcon.contentMode = .scaleAspectFit
pill.addSubview(pillIcon)

pillLabel.font = .systemFont(ofSize: 13, weight: .heavy)
pillLabel.textColor = Self.pillInk
pillLabel.textAlignment = .left
pill.addSubview(pillLabel)
```

- [ ] **Step 3: Adicionar o layout dinâmico da pill**

Dentro de `StationAnnotationView`, adicionar este método (ex.: logo após o
`init?(coder:)`):

```swift
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
```

- [ ] **Step 4: Preencher o código quando a annotation é atribuída**

Dentro de `StationAnnotationView`, adicionar o override (ex.: logo após as
propriedades declaradas no Step 1):

```swift
override var annotation: MKAnnotation? {
    didSet {
        guard let station = annotation as? StationAnnotation else { return }
        pillLabel.text = station.code
        layoutPill()
    }
}
```

- [ ] **Step 5: Compilar para o simulador**

Run:
```bash
xcodebuild -project FocusTrain.xcodeproj -scheme FocusTrain \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -configuration Debug CODE_SIGNING_ALLOWED=NO build
```
Expected: `** BUILD SUCCEEDED **`. Visualmente idêntico (pill ainda oculta).

- [ ] **Step 6: Commit**

```bash
git add FocusTrain/Features/FocusSession/Views/Components/DestinationMapView.swift
git commit -m "feat(picker): add hidden code-pill subviews to station pin"
```

---

### Task 3: Mostrar a pill no estado selecionado (morph disco↔pill)

**Files:**
- Modify: `FocusTrain/Features/FocusSession/Views/Components/DestinationMapView.swift` (classe `StationAnnotationView`: `apply`, `startPulse`, `prepareForReuse`)

- [ ] **Step 1: Trocar `apply(state:)` para alternar disco/pill**

Substituir o método `apply(state:)` inteiro por:

```swift
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
```

- [ ] **Step 2: Adaptar `startPulse` para aceitar a forma de cápsula**

Substituir o método `startPulse(color:)` inteiro por:

```swift
private func startPulse(color: UIColor, capsule: Bool) {
    if capsule {
        pulse.frame = pill.frame
        pulse.cornerRadius = Self.pillHeight / 2
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
```

- [ ] **Step 3: Resetar a pill no reuso**

Substituir `prepareForReuse()` inteiro por:

```swift
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
```

- [ ] **Step 4: Compilar para o simulador**

Run:
```bash
xcodebuild -project FocusTrain.xcodeproj -scheme FocusTrain \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -configuration Debug CODE_SIGNING_ALLOWED=NO build
```
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 5: Commit**

```bash
git add FocusTrain/Features/FocusSession/Views/Components/DestinationMapView.swift
git commit -m "feat(picker): render selected destination as accent code pill"
```

---

### Task 4: Verificação visual

**Files:** nenhum (verificação).

O arquivo já tem `#Preview("DestinationMap")` que faz `m.select(4, from: .ruler)` —
ou seja, o índice 4 fica selecionado. Use-o como prova visual.

- [ ] **Step 1: Abrir o preview no Xcode**

Abrir `FocusTrain/Features/FocusSession/Views/Components/DestinationMapView.swift`
no Xcode e ativar o canvas do `#Preview("DestinationMap")`.

Expected (checklist):
- O destino selecionado (índice 4) aparece como **pill brass** com o ícone
  `tram.fill` + código de 3 letras (ex. `ROD`), centrada sobre a estação.
- Conteúdo da pill (ícone + texto) em tom **escuro** sobre o brass.
- As estações já passadas (0–3) são **discos brancos**; as futuras (5+) são
  **discos apagados** (ghost). Nenhuma delas mostra código.
- A pill tem um leve glow brass e o anel de pulse acompanha a forma de cápsula.

- [ ] **Step 2: Rodar no simulador e arrastar a régua**

Rodar o app no simulador (`iPhone 17 Pro`), navegar até o picker de duração e
arrastar a `TimeRulerView`.

Expected:
- A pill **acompanha** o novo destino conforme a régua muda; a estação anterior
  volta a ser **disco**.
- Selecionar uma estação por **toque** continua funcionando (o tap-target é o
  disco de 36×36; a pill transborda mas não rouba toques de vizinhos).
- Pan (2 dedos) e pinch-zoom seguem funcionando sem regressão.

- [ ] **Step 3: Marcar a verificação como concluída**

Se algum item falhar, registrar o desvio e voltar à task correspondente. Caso
contrário, a feature está completa.

---

## Self-Review

- **Spec coverage:** badge só no selecionado (Task 3) ✓; formato pill ícone+código (Task 2) ✓; accent brass + conteúdo escuro (Task 2/3) ✓; largura dinâmica + centralização (Task 2 `layoutPill`) ✓; pulse adaptado à cápsula (Task 3) ✓; código vindo de `dest.code` (Task 1) ✓; ghost/solid inalterados (Task 3) ✓; a11y inalterada (nenhuma task mexe em `applyA11y`) ✓.
- **Placeholders:** nenhum — todo passo de código tem o código completo.
- **Type consistency:** `StationAnnotation(index:title:code:)` definido na Task 1 e usado na Task 1 Step 2 ✓; `startPulse(color:capsule:)` redefinido na Task 3 Step 2 e chamado nas duas vias de `apply` na Task 3 Step 1 ✓; `pill`/`pillIcon`/`pillLabel`/`layoutPill()` definidos na Task 2 e usados na Task 3 ✓.
