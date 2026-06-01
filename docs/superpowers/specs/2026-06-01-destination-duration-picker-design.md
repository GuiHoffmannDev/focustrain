# FocusTrain — Seleção de Destino/Duração ("Escolha seu Destino")

**Data:** 2026-06-01
**Fase:** Nova tela no fluxo de embarque (substitui a seleção de duração do Compose)
**Direção:** Um radar/dial circular + régua de tempo arrastável + carrossel de destinos, onde **escolher um destino É escolher a duração** da sessão. Metáfora: distância do voo ≈ tempo de foco.

---

## 1. Visão geral

Esta tela substitui a seleção de duração atual (4 chips `SessionDuration` dentro de `ComposeJourneyView`) por um seletor único onde **o destino codifica a duração**. Três controles sincronizados — **radar**, **régua** e **carrossel** — leem e escrevem a mesma seleção. Confirmar avança para o seat picker (ordem do fluxo preservada).

O brief original descrevia tema de aviação, accent amarelo e "Book My Flight"; **isto foi reconciliado para o app real**: FocusTrain é metáfora de **trem**, accent **branco**, CTA **"Depart"**, códigos de estação. As decisões abaixo foram confirmadas com o usuário.

### Decisões confirmadas (calibração)
1. **Tema:** Trem + branco. Sem amarelo, sem "Book My Flight", sem framing IATA na cópia.
2. **Modelo:** Destino = duração. Lista curada fixa; o destino define rota **e** duração.
3. **Régua:** Discreta — snapa para destinos (sem minutos intermediários ambíguos).
4. **Faixa:** 15–90 min, 9 paradas.
5. **Destinos:** Ladder curado fixo a partir do `StationPool` (coords reais p/ o mapa). Origem = cidade atual.
6. **Fluxo:** Ordem atual mantida — esta tela ocupa o lugar do `ComposeJourneyView` (antes do seat picker).
7. **Métrica secundária:** Distância estilizada que cresce com o tempo (não km literal).
8. **Cenário:** `ScenarioChips` permanece nesta tela, abaixo do carrossel.

### Defaults assumidos (vetáveis nesta revisão)
- **Aposentar `ComposeJourneyView` + `ComposeJourneyViewModel`** (a lógica de seed de scenario/mapStyle e `makeTicket()` migra para o novo model).
- **Distância estilizada** nesta tela; **boarding pass permanece intocado** (segue calculando km real great-circle das coords). Os dois números podem divergir levemente — aceito como flavor.
- **Ladder de 9 paradas** conforme tabela em §4.

### Restrições invioláveis (do projeto)
- **Nunca editar `.pbxproj`.** Arquivos novos só são *dropados* nas pastas (PBXFileSystemSynchronizedRootGroup). Avisos stale do SourceKit em arquivos novos são esperados — ignorar, confiar no build.
- **Toda cópia user-facing via `Localizable.strings`** (`NSLocalizedString`), PT-BR como base. Novas chaves `durationPicker.*`.
- **Accent é BRANCO** (`FT.Palette.brandRail = #FFFFFF`). Brass (`#E0A458`) é o calor secundário.
- **Preservar composições existentes.** Cadência visual idêntica às telas vizinhas; `BoardingPass`, ride e mapa **não mudam**.
- **Verificar com `xcodebuild`** no simulador iPhone 17 Pro a cada incremento.
- **iOS 17+ / macOS 14+**, SwiftUI puro, codebase Multiplatform único. Código novo macOS-safe via `#if os(iOS)` (como `TearHaptics` já faz).

---

## 2. Integração no fluxo e arquivos

Fluxo mantido: **Home → [esta tela] → SeatPicker → BoardingPass → ride.**
`RootView.Route.compose` passa a apresentar **`DurationPickerView`** em vez de `ComposeJourneyView`; `onDepart(ticket)` continua empurrando `Route.seatPicker(ticket)`. SeatPicker → BoardingPass **inalterados**.

### Arquivos novos
- `Features/FocusSession/Models/Destination.swift`
- `Features/FocusSession/ViewModels/DurationPickerModel.swift`
- `Features/FocusSession/Views/DurationPickerView.swift` (container)
- `Features/FocusSession/Views/Components/RadarDialView.swift`
- `Features/FocusSession/Views/Components/DestinationPin.swift`
- `Features/FocusSession/Views/Components/TimeRulerView.swift`
- `Features/FocusSession/Views/Components/DestinationCarouselView.swift`
- `Features/FocusSession/Views/Components/DestinationCard.swift`
- `Features/BoardingPass/Services/DetentHapticsService.swift`

### Arquivos editados
- `ContentView.swift` (`RootView.destination(for:)`) — trocar `ComposeJourneyView` por `DurationPickerView`.
- `Localizable.strings` (todas as línguas) — chaves `durationPicker.*`.

### Aposentados
- `ComposeJourneyView.swift`, `ComposeJourneyViewModel.swift` (lógica migra; arquivos removidos das pastas — sem editar `.pbxproj`).
- `ScenarioChips` é **reutilizado** como está.

---

## 3. Modelo de estado — single source of truth

`@MainActor @Observable final class DurationPickerModel`.

- **Verdade única:** `selectedIndex: Int` em `let destinations: [Destination]`. Tudo o mais é **derivado**: `selectedDestination`, ângulo da agulha, offset-alvo da régua, card centralizado.
- **Estado adicional:** `scenario: FocusScenario`, `mapStyle: MapStyle` (seedados de `UserDefaults` exatamente como o `ComposeJourneyViewModel` faz hoje), `origin: Station`.
- **`makeTicket() -> Ticket`:** origem = `origin`; destino = `selectedDestination.station`; `durationMinutes = selectedDestination.minutes`; `scenario`, `mapStyle`, `code = Ticket.makeCode()`. Mesma forma de `Ticket` de hoje — nada downstream muda.

### Sincronização sem loops
Risco clássico: arrastar régua → model → carrossel auto-scrolla → callback do scroll re-escreve no model → briga com o dedo.

Guarda: **um único** `enum InteractionSource { case none, ruler, radar, carousel }`.
- A view sob o dedo seta `interactionSource` no início do gesto e limpa no fim.
- Um controle só **escreve** no model quando **é** a fonte ativa; os outros dois apenas **leem** e animam para casar, **suprimindo** o próprio write-back.
- O `scrollPosition`/`ScrollViewReader` do carrossel é envolvido por essa guarda para a centralização programática **não ecoar**.

Mutator único: `select(_ index: Int, from source: InteractionSource)` — faz clamp, dedup e dispara o tick de detent **apenas quando o índice realmente muda**.

---

## 4. Ladder de destinos + origem

Discreto, 9 paradas, 15–90 min, curado do `StationPool` (coords reais). Proposta (tudo tunável — é só dado):

| min | code | cidade | dist. nominal |
|-----|------|--------|---------------|
| 15  | LIS  | Lisbon     | ~250 km  |
| 20  | MAD  | Madrid     | ~400 km  |
| 25  | PAR  | Paris      | ~600 km  |
| 30  | ROM  | Rome       | ~850 km  |
| 40  | IST  | Istanbul   | ~1300 km |
| 50  | DXB  | Dubai      | ~2000 km |
| 60  | DEL  | Delhi      | ~3000 km |
| 75  | BKK  | Bangkok    | ~4500 km |
| 90  | TYO  | Tokyo      | ~6500 km |

- `nominalKm` = distância **estilizada** (monotônica com o tempo), exibida em cards/radar. Não é km real.
- **Origem = cidade atual** via `CurrentCityResolver` (sintetiza `Station`: `code` = 3 letras do nome ou neutro tipo "ORG"; coords do resolver). **Localização negada → origem = cidade aleatória do `StationPool`** (alinhado à filosofia de fallback da Home).
- **Ângulos dos pins no radar são curados** (espalhamento uniforme no anel), **não** rumos geográficos — layout estável independente da origem, coerente com a referência.

### Modelo `Destination`
`struct Destination: Identifiable, Hashable { let station: Station; let minutes: Int; let nominalKm: Int; let radarAngle: Angle }` (+ `code`, `city` derivados de `station`).

---

## 5. Os três controles

Layout (topo→base), mesma cadência das telas vizinhas (bg preto, backdrop glow `brandRail.opacity(0.10)`, reveal em mola, toolbar com back chevron, CTA fixo embaixo):
**Header → RadarDialView → leitura grande do tempo + TimeRulerView → DestinationCarouselView → ScenarioChips → CTA "Depart".**

### 5.1 RadarDialView
- Ponto de origem no centro; **agulha** (`rotationEffect`) que dá mola até o pin selecionado.
- 9 `DestinationPin` posicionados em `radarAngle` no anel. Selecionado = **branco sólido**; demais = outline/dim (`textMuted`).
- Tocar num pin → `select(from: .radar)`.
- **Perf:** pins são estáticos; só a agulha anima.

### 5.2 TimeRulerView (controle principal)
- Odômetro horizontal; **indicador fixo no centro** (triângulo pra baixo, branco); a **escala se move sob o indicador**.
- Ticks + labels desenhados em **`Canvas`** (uma view, não N subviews → scrub liso 60/120fps).
- `DragGesture` atualiza um offset local ao vivo; a cada marca de destino cruzada dispara **tick de detent**; ao soltar, **snapa** para o destino mais próximo e comita `select(from: .ruler)`.
- Sem arrasto, o offset é **derivado** de `selectedIndex` (taps no radar/card animam a régua).

### 5.3 DestinationCarouselView
- `ScrollView` horizontal de `DestinationCard` (code / city / time + dist. nominal).
- Selecionado destacado (fill branco, texto `ink`) — espelha o estilo do chip de duração atual.
- Tocar → `select(from: .carousel)`. Auto-centraliza o selecionado via `scrollPosition`, com guarda.

---

## 6. Háptico — `DetentHapticsService`

Novo serviço modelado na estrutura do `TearHapticsService` (mesma família, primitivo correto):
- `CHHapticEngine.capabilitiesForHardware().supportsHaptics` + guarda `isiOSAppOnMac` → Core Haptics **transiente** (um tick curto e seco por marca — **não** o pattern contínuo de tear).
- Fallback sem Core Haptics → `UIImpactFeedbackGenerator(style: .rigid)`.
- macOS → `Noop`.
- `prepare()` no `onAppear`. Dispara por marca cruzada no arrasto da régua, e uma vez por mudança de seleção via radar/card.

**Por que serviço novo e não estender o tear:** detent é evento *transiente*; o tear é um *player contínuo* modulado por velocidade — primitivo errado para reutilizar diretamente.

---

## 7. Acessibilidade / Dynamic Type / macOS

- Régua = **um** `.accessibilityElement` com trait **`.adjustable`**: swipe ↑/↓ no VoiceOver → `increment/decrement` move `selectedIndex`; `accessibilityValue` = ex. "Tokyo, 90 minutos". É também o **caminho sem-arrasto** (e cada card é tocável independentemente).
- Labels usam fontes `FT.Typography` (system, Dynamic Type); `minimumScaleFactor` onde o espaço aperta.
- **macOS:** arrasto via trackpad/mouse; háptico `Noop`; `.adjustable`/taps cobrem teclado/ponteiro.

---

## 8. Distância estilizada vs. boarding pass

Esta tela mostra `nominalKm` (cresce com o tempo). O **boarding pass permanece inalterado** e segue calculando km real great-circle das coords origem/destino — os dois números podem divergir levemente. Aceito como flavor (telas distintas; não redesenhar o pass). *Veto possível: mostrar km real ou nenhuma distância aqui.*

---

## 9. Edge cases

- Localização negada → origem aleatória do `StationPool`.
- Scrub rápido → detents só na marca **efetivamente** cruzada (dedup por índice).
- Movimentos programáticos nunca ecoam (guarda de fonte).
- **Reduce Motion** → agulha/scroll usam cross-fade em vez de mola.

---

## 10. Fora de escopo

Sem mudanças no boarding pass, mapa, ride ou persistência. Sem novos models de `Ticket`. O ladder de 9 paradas, as distâncias nominais e os ângulos do radar são **dados** — retunáveis trivialmente.

---

## 11. Ordem de implementação (Foundation-up, um incremento verificável por vez)

1. `Destination` + ladder estático + `DurationPickerModel` (verdade + `makeTicket()` + guarda de fonte). Sem UI.
2. `DetentHapticsService` (+ fallback + Noop macOS).
3. `TimeRulerView` (Canvas, drag, snap, detent) — controle principal isolado.
4. `RadarDialView` + `DestinationPin` (agulha animada).
5. `DestinationCarouselView` + `DestinationCard` (scrollPosition guardado).
6. `DurationPickerView` (compõe tudo + `ScenarioChips` + CTA) e troca em `RootView`.
7. Acessibilidade (`.adjustable`, Dynamic Type, Reduce Motion) + `Localizable.strings`.
8. Aposentar `ComposeJourneyView`/`ComposeJourneyViewModel`.

Cada passo: build + `xcodebuild` no iPhone 17 Pro antes do próximo.
