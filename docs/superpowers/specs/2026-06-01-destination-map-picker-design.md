# FocusTrain — Picker de Destino em Mapa ("Escolha sua Viagem de Trem")

**Data:** 2026-06-01
**Fase:** Reescrita da superfície visual do `DurationPickerView` (mapa MapKit no lugar do radar/carrossel)
**Direção:** Um mapa MapKit escuro 2D ocupando a tela, com a régua de tempo embaixo. Arrastar a régua faz crescer um anel a partir da origem e **revela estações** da ladder curada; tocar um pin seleciona a estação. **Escolher o destino É escolher a duração.**

> **Supersessão:** Este spec **substitui a superfície visual** descrita em
> `2026-06-01-destination-duration-picker-design.md` (radar + carrossel + régua).
> O **modelo, a ladder, a régua, o `ScenarioChips`, o CTA e o fluxo permanecem**;
> apenas o radar/carrossel saem e entra o mapa. Decisão confirmada com o usuário
> em 2026-06-01 ("Substitui o radar").

---

## 1. Visão geral

A tela continua sendo a etapa **escolher duração + destino** do fluxo de embarque
(no lugar do antigo `ComposeJourneyView`, antes do seat picker). A novidade é a
**superfície**: em vez de um dial abstrato, um **mapa-múndi MapKit monocromático
escuro** mostra a origem do usuário, um **anel cosmético** que cresce conforme a
régua, e as **9 estações da ladder** como pins de trem — apareceendo em fantasma
e **solidificando** conforme entram no alcance.

O `selectedIndex` da ladder permanece a **única fonte de verdade**: ele é
simultaneamente a duração e a estação selecionada. Régua e tap-no-pin escrevem
nele pelo mesmo mutator `select(_:from:)`; anel e câmera são **sinks puros** que
só leem — eliminando qualquer loop de eco.

### Decisões confirmadas (calibração 2026-06-01)
1. **Escopo:** O mapa **substitui** `RadarDialView`, `DestinationCarouselView`,
   `DestinationPin`. `TimeRulerView`, label de minutos, `ScenarioChips`,
   `CTAButton "Embarcar"` permanecem.
2. **Modelo tempo→distância→estações:** **Ladder curada** (mantida). Duração
   mapeia 1:1 a uma cidade curada; a régua revela as próximas como "em alcance".
   Nenhum reveal geográfico de cidades arbitrárias do `StationPool`.
3. **Tecnologia do mapa:** **`UIViewRepresentable` + `MKMapView`** — consistente
   com `RouteMapView` e `GlobeHomeView`. Não SwiftUI `Map`.
4. **Projeção:** **Plano 2D** (não globo). Câmera = centro + zoom.
5. **Metáfora do raio:** **Anel cosmético no origin** (`MKCircle`), `raio =
   f(nominalKm)` estilizado — não geograficamente literal. O usuário aceitou que
   o anel pode não cercar os pins reais com precisão.
6. **Revelação dos pins:** **Fantasma → solidifica.** Pins fora de alcance ficam
   pequenos/esmaecidos; ao entrar no alcance, solidificam e começam a pulsar.

### Defaults assumidos (vetáveis nesta revisão)
- **Borda do pin selecionado = brass `#E0A458`**, não amarelo. O brief pedia
  "borda amarela", mas o app é monocromático de accent **branco** e o spec
  anterior já reconciliou "sem amarelo". Brass é o calor secundário estabelecido
  (já usado em `PulsingPin`). Pin não-selecionado = branco; selecionado = branco
  + borda brass.
- **Câmera = reframe-para-caber, sem fly-to por tick.** A câmera re-enquadra para
  conter origem + anel + pins sólidos. **O reframe acontece no *settle* da
  seleção** (fim do arrasto da régua / tap no pin), **não a cada tick** do
  arrasto — durante o arrasto ao vivo só o anel cresce e os pins acendem, a
  câmera fica parada (evita jank/enjoo). Sem fly-to-zoom extra ao tocar um pin
  (trivial de somar depois se quiser).
- **`f()` do anel:** `ringRadiusMeters = Double(selectedDestination.nominalKm) *
  1_000 * ringScale`, com `ringScale` default `1.0` (constante tunável). Faixa
  resultante ≈ 250 km … 6500 km de raio.
- **Reframe inclui só os pins sólidos** (índices `0...selectedIndex`) + a origem
  + o `boundingMapRect` do anel. Fantasmas não puxam o enquadramento.

### Restrições invioláveis (do projeto)
- **Nunca editar `.pbxproj`.** Arquivos novos são dropados nas pastas synced
  (`PBXFileSystemSynchronizedRootGroup`). Avisos stale do SourceKit em arquivos
  novos são esperados — ignorar, confiar no build.
- **Toda cópia user-facing via `NSLocalizedString`** sobre `Localizable.xcstrings`,
  PT-BR como base. Novas chaves sob `durationPicker.*`.
- **Accent é BRANCO** (`FT.Palette.brandRail = #FFFFFF`). Brass (`#E0A458`) é o
  calor secundário.
- **Preservar composições existentes.** Cadência visual idêntica às telas
  vizinhas; `BoardingPass`, ride e o mapa de sessão (`RouteMapView`) **não mudam**.
- **Verificar com `xcodebuild`** no simulador iPhone 17 Pro a cada incremento.
- **iOS 17+ / macOS 14+**, SwiftUI puro, codebase Multiplatform único. Código
  novo macOS-safe via `#if os(iOS)`.

---

## 2. Integração no fluxo e arquivos

### Inalterado a montante/jusante
- `ContentView.swift:81` apresenta `DurationPickerView(onDepart:onBack:)` — o
  **contrato de callback é idêntico**, nada muda no `ContentView`.
- `DurationPickerModel`, `Destination.ladder`, `StationPool`, `Ticket`,
  `makeTicket()`, `DetentHapticsService`, `CurrentCityResolver` — reusados.
- `RouteMapView` / `GlobeHomeView` / `MapStyle+MapKit` — não tocados, mas servem
  de **referência de padrão** (Coordinator, dark config, fitRect).

### Retirado
- `Features/FocusSession/Views/Components/RadarDialView.swift` — **deletar**.
- `Features/FocusSession/Views/Components/DestinationCarouselView.swift` — **deletar**.
- `Features/FocusSession/Views/Components/DestinationPin.swift` — **deletar**.
- `Features/FocusSession/Views/Components/DestinationCard.swift` — **deletar**
  (grep confirma: usado só pelo `DestinationCarouselView`).

> Como são synced file groups, deletar o arquivo basta — não mexe no `.pbxproj`.

### Novo
- `Features/FocusSession/Views/Components/DestinationMapView.swift`
  — `UIViewRepresentable` + `MKMapView` + `Coordinator`. Contém também
  `StationAnnotation` (`MKAnnotation`) e `StationAnnotationView` (`MKAnnotationView`).
- (Opcional) Se `DestinationMapView.swift` crescer muito, separar
  `StationAnnotationView` em arquivo próprio. Default: tudo num arquivo,
  como `RouteMapView.swift` já faz com suas annotations.

### Modificado
- `Features/FocusSession/Views/DurationPickerView.swift` — corpo reescrito
  (layout map-cêntrico; ver §4).
- `Features/FocusSession/ViewModels/DurationPickerModel.swift` — `interactionSource`
  troca `.radar/.carousel` por `.map`; adiciona derivados (ver §3).
- `Resources/Localizable.xcstrings` — novas chaves (ver §8).

---

## 3. Modelo de estado (`DurationPickerModel`)

Sem novo view model. Estende-se o existente.

```swift
enum InteractionSource: Equatable { case none, ruler, map }   // era none/ruler/radar/carousel
```

`selectedIndex` continua a única propriedade escrita. `select(_:from:)`
(clamp + dedup + tick háptico) **reusado sem mudança** — só os sources mudam de nome.

Derivados computados (read-only, sem armazenamento extra):

```swift
/// Quantas estações estão "em alcance" (sólidas). 0...selectedIndex inclusive.
var reachableCount: Int { selectedIndex + 1 }

/// Raio cosmético do anel, em metros. Estilizado a partir do nominalKm.
var ringRadiusMeters: CLLocationDistance {
    Double(selectedDestination.nominalKm) * 1_000 * Self.ringScale
}
static let ringScale: Double = 1.0   // tunável
```

`reachableStations` / `ghostStations` derivam de `selectedIndex` na hora de
configurar as annotations (não precisam ser propriedades).

---

## 4. Layout da tela (`DurationPickerView`)

`ZStack` em tela cheia:

```
ZStack
├─ DestinationMapView(model:)            // ignoresSafeArea, ocupa tudo
├─ scrim gradiente topo→base (sutil)     // legibilidade do título + chrome
├─ VStack (top)
│   └─ título "durationPicker.title"     // overlay sobre o mapa, alinhado leading
└─ VStack (bottom)
    ├─ label de minutos (numericText)    // "30 min" centralizado
    ├─ TimeRulerView(model:)             // REUSO, sem mudança
    ├─ ScenarioChips(...)                // REUSO (binding como hoje)
    └─ CTAButton "compose.depart" "Embarcar" → onDepart(model.makeTicket())
```

- A faixa inferior (régua + chips + CTA) fica sobre um **gradiente preto
  base→transparente** para legibilidade contra o mapa.
- Animação de entrada `appeared` (spring) preservada como hoje.
- `onAppear`: `model.prepareHaptics()`, `resolver.bootstrap()`.
- `onChange(resolver.cityName)`: `model.setOrigin(city:coordinate:)` — quando a
  origem muda, `DestinationMapView.updateUIView` re-centra (ver §6).

---

## 5. `DestinationMapView` (UIViewRepresentable)

### Configuração (`makeUIView`)
Espelha `GlobeHomeView`/`RouteMapView`:
- `preferredConfiguration = model.mapStyle.mapConfiguration(showLabels:)`
  (default `.monochrome` → `MKStandardMapConfiguration(emphasisStyle: .muted)`).
- `isRotateEnabled = false`, `isPitchEnabled = false`, `showsCompass = false`,
  `showsScale = false`, `pointOfInterestFilter = .excludingAll`,
  `overrideUserInterfaceStyle = .dark`.
- **Interação do usuário com o mapa:** scroll/zoom **desabilitados** por default
  (`isScrollEnabled = false`, `isZoomEnabled = false`) — a navegação é via régua
  e taps; o mapa é uma superfície dirigida, não um mapa livre. *(Vetável: se
  quiser pan/zoom livre, habilitar — mas aí o reframe automático compete com o
  gesto do usuário.)*
- Adiciona o **anel** (`MKCircle`) e as **9 `StationAnnotation`** (cada uma com
  seu `index`). Origem como uma `StationAnnotation` especial ou um marcador
  dedicado (reusar o estilo de `PulsingPin`/endpoint dot).
- `applyCamera`/`fit` inicial enquadrando origem + anel + pins sólidos iniciais.

### Atualização (`updateUIView`) — o sink
Idempotente. Lê `model` e reflete:
1. **Estilo** mudou? Reaplica `mapConfiguration`.
2. **Origem** mudou? Atualiza o marcador de origem e re-centra.
3. **Anel:** remove o `MKCircle` antigo, adiciona um novo com
   `radius = model.ringRadiusMeters` centrado na origem.
4. **Pins:** para cada `StationAnnotationView`, aplica estado:
   - `index < selectedIndex` → **sólido**, pulsando, não-selecionado.
   - `index == selectedIndex` → **sólido + selecionado** (borda brass, maior).
   - `index > selectedIndex` → **fantasma** (pequeno, ~30% opacity, sem pulso).
5. **Câmera (reframe condicional):**
   - Se `model.interactionSource == .ruler` (arrasto ao vivo) → **não reenquadra**
     (só anel/pins mudam).
   - Senão (`.map` ou `.none` pós-arrasto) → `setVisibleMapRect(union, animated:)`
     onde `union` = `MKCircle.boundingMapRect` ∪ rects da origem e dos pins
     sólidos, com `edgePadding` (top p/ título, bottom p/ régua+chips+CTA).
6. **Deseleciona** qualquer annotation selecionada pelo MapKit
   (`mapView.deselectAnnotation(_, animated: false)`) — a seleção visual é nossa,
   não a default do MapKit (sem callout).

### Coordinator (`MKMapViewDelegate`)
- `rendererFor overlay`: `MKCircleRenderer` com `strokeColor` branco ~0.5 alpha,
  `lineWidth 1.5`, `fillColor` branco ~0.04 (halo levíssimo).
- `viewFor annotation`: dequeue/cria `StationAnnotationView`; marcador de origem
  tem reuseID próprio.
- `didSelect annotation`: se for `StationAnnotation`, chama
  `model.beginInteraction(.map); model.select(ann.index, from: .map);
  model.endInteraction()`. (SwiftUI então re-roda `updateUIView` → reframe.)

---

## 6. `StationAnnotationView` (pin de trem) e pulso

`MKAnnotationView` (UIKit), reusável via dequeue.

- **Glifo:** `tram.fill` branco num disco/cápsula escura — coerente com o
  `TrainAnnotationView` de `RouteMapView` (consistência visual entre as telas).
- **Estados** via `func apply(state: PinState)` onde
  `enum PinState { case ghost, solid, selected }`:
  - `ghost`: escala ~0.6, alpha ~0.3, sem pulso, sem borda.
  - `solid`: escala 1.0, alpha 1.0, borda branca fina, **pulso ativo**.
  - `selected`: escala ~1.15, borda **brass `#E0A458`** 2pt, glow brass sutil,
    pulso ativo.
- **Pulso (performático):** uma sub-layer "ring" com `CABasicAnimation`
  (scale 1.0→1.25 + opacity 0.6→0) `repeatCount = .infinity`, `duration ~2.0s`.
  Iniciar/parar a animação ao entrar/sair de `solid|selected`. Só ≤ 9 pins, dos
  quais ≤ 9 pulsando — custo trivial, 120fps.
- **Label da cidade:** opcional sob o pin (texto branco pequeno). Default: mostrar
  só no pin **selecionado** para não poluir; fantasmas/sólidos sem label.
  *(Vetável.)*

---

## 7. Sincronização régua ↔ raio ↔ estações ↔ câmera

| Evento | Fonte | Escreve | Sinks reagem |
|---|---|---|---|
| Arrasto régua | `.ruler` | `select(i, .ruler)` → `selectedIndex` + tick | anel cresce, pins acendem/apagam **(câmera parada)** |
| Fim do arrasto | — | `endInteraction()` → `.none` | `updateUIView` re-roda → **câmera reframe** |
| Tap no pin | `.map` | `select(i, .map)` → `selectedIndex` + tick | anel ajusta, pins, **câmera reframe** |
| VO incremento | `.ruler` | `select(±1, .ruler)` | idem fim de arrasto |
| Origem resolvida | — | `setOrigin(...)` | re-centra marcador + câmera |

**Invariante anti-eco:** anel e câmera **nunca** chamam `select`. A única escrita
vem de régua e tap. `select` faz dedup (ignora no-op) — taps repetidos no mesmo
pin não re-tickam nem reanimam.

---

## 8. Localização (`Localizable.xcstrings`, base PT-BR)

Reaproveita: `durationPicker.title`, `durationPicker.minutes`,
`durationPicker.ruler.a11yLabel`, `compose.depart`, `compose.scenario.title`.

Novas chaves:
- `durationPicker.station.a11y` = `"%1$@, %2$d minutos"` (cidade, minutos).
- `durationPicker.station.a11ySelected` = `"%1$@, %2$d minutos, selecionada"`.
- (Se o título atual não couber sobre o mapa, manter o mesmo texto; sem chave nova.)

---

## 9. Origem, offline, macOS, acessibilidade

- **Origem:** `CurrentCityResolver` (cidade real; fallback `StationPool`
  aleatório no `init` do model). Sem novo pedido de permissão aqui — o
  `bootstrap()` já é chamado no `onAppear` (mesma UX de hoje).
- **Offline:** sem tiles o `MKMapView` fica escuro/cinza, mas **anel, pins,
  régua, seleção, minutos e Embarcar funcionam** (tudo desenhado por cima,
  coords locais). Degradação graciosa, sem estado de erro.
- **macOS / Mac Catalyst:** háptico Noop (já tratado por `DetentHaptics.make()`);
  régua e tap já são gesto/click; `CABasicAnimation` e `MKMapView` ok no
  Catalyst. Sem `CoreHaptics` fora do `#if os(iOS)`.
- **Acessibilidade:**
  - Cada `StationAnnotationView` com `isAccessibilityElement = true` e
    `accessibilityLabel` via `durationPicker.station.a11y[/Selected]`.
  - Régua já expõe VO + `accessibilityAdjustableAction` (alternativa sem arrasto
    fino — incrementa/decrementa estações). Mantida.
  - Label de minutos com Dynamic Type.
  - `MKMapView` em si: `accessibilityElementsHidden` para o basemap se o VO ficar
    ruidoso; manter os pins como elementos acessíveis.

---

## 10. Verificação e testes

- **Self-checks via `#Preview`** (padrão do codebase, ex. "Destination ladder
  self-check", "DurationPickerModel self-check"):
  - Novo preview que valida derivados do model: `reachableCount` monotônico,
    `ringRadiusMeters` crescente com `selectedIndex`, `ringRadiusMeters`
    positivo, e que `InteractionSource` não tem mais `.radar/.carousel`.
  - Preview de `DestinationMapView` (model com `NoopDetentService`) renderizando
    em fundo preto — inspeção visual de anel + pins + estados.
- **Build/UX:** `xcodebuild` no simulador **iPhone 17 Pro** a cada incremento;
  rodar e conferir: arrasto da régua cresce anel + acende pins sem mover câmera;
  soltar reenquadra; tap no pin seleciona + reenquadra; háptico tica por detent;
  Embarcar gera o `Ticket` correto.
- **Regressão:** confirmar que `ContentView` ainda compila e o fluxo
  Compose → seat picker → boarding pass segue intacto (callbacks inalterados).

---

## 11. Fora de escopo (YAGNI)

- Reveal geográfico de cidades arbitrárias do `StationPool` (decidido: ladder).
- Globo 3D / projeção ortográfica.
- Pan/zoom livre do mapa pelo usuário.
- Fly-to-zoom cinematográfico ao tocar um pin (default é reframe simples).
- Clusterização de pins (só 9, desnecessário).
- Mudanças em `BoardingPass`, `RouteMapView`, ride ou histórico.
- Rota geodésica desenhada na tela de picker (escolha foi anel, não rota).
