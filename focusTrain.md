# 🚂 FocusTrain — Plano de Implementação

> App iOS de produtividade/foco que transforma cada sessão de concentração em uma **viagem de trem**, seguindo rigorosamente a UI/UX do FocusFlight.
> 

---

## 1. Visão Geral do Projeto

| Item | Detalhe |
| --- | --- |
| **Nome** | FocusTrain |
| **Plataforma** | iOS 17+ |
| **Linguagem** | Swift 5.9+ / SwiftUI |
| **Conceito** | Cada sessão de foco = uma viagem de trem entre estações |
| **Referência** | FocusFlight iOS Onboarding (13 telas) |

---

## 2. Mapeamento de Metáforas: Avião → Trem

| FocusFlight (Avião) ✈️ | FocusTrain (Trem) 🚂 |
| --- | --- |
| Flight / Voo | Journey / Viagem |
| Boarding Pass | Train Ticket / Bilhete de Trem |
| Airport codes (LHR, CDG) | Station codes (GRU, LUZ, SPO) |
| Airplane Mode ✈️ | Tunnel Mode 🚇 |
| Takeoff / Touchdown | Departure / Arrival (Partida / Chegada) |
| Seat (21A) | Wagon 3, Seat 12B |
| Flight route (linha reta) | Rail route (curva seguindo trilhos) |
| Airport icon (avião) | Station icon (trem/locomotiva) |
| "Focus Boarding Pass" | "Focus Train Ticket" |
| "Focus History" | "Journey Log" |
| "Fly" (cenário) | "Ride" (cenário) |
| Barcode | QR Code |
| Globe/Earth view | Railway map / topographic view |

---

## 3. Telas do Onboarding — Mapeamento Completo

### Tela 0 — Welcome Screen

- **Fundo**: Preto sólido
- **Título**: "Welcome aboard! 👋" — mantém idêntico
- **Subtítulo**: "Your journey to deep focus begins here."
- **Botão**: "Hi!" — branco, pill shape, full-width
- **Rodapé**: Logo "FocusTrain" no canto inferior esquerdo

### Tela 1 — Pergunta de Engajamento

- **Animação**: Texto anterior sobe com fade-out (escala reduzida, opacidade ~30%)
- **Texto**: "Do you often feel **distracted?**" — palavra destaque em **azul/índigo (#6C7AE0)**
- **Botão**: "Yes, I do."
- ✅ Manter 100% idêntico ao FocusFlight

### Tela 2 — Solução: Hyperfocus

- Textos anteriores sobem como "fantasmas" (fade)
- "There's a solution: **Hyperfocus.**"
- Descrição explicativa
- **Botão**: "What's the key to hyperfocus?"
- ✅ Manter 100% idêntico

### Tela 3 — Apresentação da Marca

- **Texto**: "That's why we created"
- **Nome**: **FocusTrain** com glow verde-esmeralda/dourado pulsante
- **Efeito**: Text glow + light burst radiante (efeito de trilhos luminosos)
- **Botão**: "Let's get started!"

### Tela 4 — Mapa com Rota Ferroviária

- **Mapa**: Monochrome escuro, estilo dark
- **Badges**: Amarelos com ícone de trem 🚂 (ex: SPO, RIO)
- **Rota**: Linha CURVA branca (não reta — seguindo trilhos)
- **Texto**: "FocusTrain turns every focus session into an exciting train journey, guiding you into **deep focus mode.**"
- **Botão**: "Continue"

### Tela 5 — Focus Train Ticket

- **Card traseiro**: Ticket com rota (SPO→RIO), status badge verde "ARRIVED"
- **Card frontal**: Train Ticket completo com QR Code
    - Campos: Origin (SPO/São Paulo), Destination (RIO/Rio de Janeiro)
    - Duration: 42m, Wagon: 3, Seat: 12B
    - Distance: 348km, Date: 2026/03/13, Boarding: Now
    - Divisor tracejado + QR Code
    - Mapa de fundo: railway network dots
- **Feature 1**: 📋 "Focus Train Ticket" — "Every journey is a ride of deep focus, from departure to arrival."
- **Feature 2**: 🕐 "Journey Log" — "Every ride marks a milestone in your focus journey."
- **Botão**: "Continue" (preto)

### Tela 6 — Choose Focus Scenario

- **Step indicator**: 4 barras (1ª ativa — preta)
- **Título**: "Choose Your Focus Scenario 🎫"
- **Subtítulo**: "Choosing these scenarios will help track different data to boost your focus efficiency."
- **Tags orgânicas** (scattered layout com rotação):
    - 📚 Explore | 🍳 Cook | 🧘 Meditate | 🧩 Focus
    - </> Code | 🚂 **Ride** (era "Fly") | 🧠 Learn | ✏️ Write
    - 📖 Read | 🔬 Research | 🏃 Exercise | 🎙️ Podcast
    - 💻 Design | 📓 Work
- **Cores**: Pastéis variados (sage, lavender, blush, cream, mint)
- **Botão**: "Continue" (preto)

### Telas 7–8 — Tunnel Mode

- **Step indicator**: 4ª barra ativa
- **Título**: "Tunnel Mode 🚇"
- **Subtítulo**: "Tunnel Mode reduces distractions by managing screen time."
- **Visual central**: Círculo grande cinza claro com ícone ampulheta+cadeado
- **Apps ao redor** (Tela 7): WhatsApp, Discord, Facebook, Instagram, McDonald's, Shopify, Telegram, YouTube
- **Tela 8**: Apps desaparecem, botão em loading state (spinner), opção "Skip" abaixo
- **Integração**: Screen Time API / FamilyControls

### Telas 9–11 — Choose Map Style

- **Step indicators**: Barras 1–3 ativas (brancas)
- **Background**: Globe 3D com espaço estrelado
- **Título**: "Choose Your Map Style 🗺️"
- **Subtítulo**: "Your chosen map will appear by default on the home and journey screens."
- **Grid 2×2**: Monochrome | Terra | Standard | Satellite
- **Seleção**: Borda branca grossa no estilo selecionado
- **Toggle**: "Labels" — OFF (cinza) / ON (verde, com globo mostrando nomes)
- **Extra train**: Toggle "Railway Lines" ON/OFF
- **Botão**: "Continue" (branco)

### Tela 12 — Welcome Final

- **Background**: Globe 3D fullscreen com labels de cidades e oceanos
- **Título overlay**: "Welcome to **FocusTrain**" (branco, centralizado)
- **Botão**: "Start Journey" (branco, pill shape)
- **Link**: "Legal" (azul, canto inferior esquerdo)

---

## 4. Design System

### 4.1 Paleta de Cores

```
// Primárias
--train-black:       #000000    // Background principal
--train-white:       #FFFFFF    // Texto principal
--train-gold:        #F5C518    // Badges de estação
--train-emerald:     #2ECC71    // Accent verde (trilhos, glow)
--train-indigo:      #6C7AE0    // Texto destaque

// Secundárias
--train-gray-100:    #F5F5F5    // Cards, botões light
--train-gray-400:    #9E9E9E    // Texto secundário
--train-gray-800:    #1E1E1E    // Superfícies
--train-green-dark:  #1B5E20    // Toggle ativo

// Cenários (tags)
--scenario-sage:     #C5D5C0
--scenario-lavender: #C5C5E0
--scenario-blush:    #E0C5D0
--scenario-cream:    #D5D0B8
--scenario-mint:     #B8D5C5
```

### 4.2 Tipografia

| Uso | Font | Size | Weight |
| --- | --- | --- | --- |
| Hero title | SF Pro Display | 36pt | Bold |
| Section title | SF Pro Display | 28pt | Bold |
| Body | SF Pro Text | 17pt | Regular |
| Caption | SF Pro Text | 13pt | Regular |
| Button | SF Pro Text | 17pt | Semibold |
| Badge | SF Pro Text | 14pt | Bold |
| Ticket fields | SF Mono | 13pt | Medium |

### 4.3 Layout

- **Margens laterais**: 24pt
- **CTA Button**: full-width (-48pt), 56pt height, radius 28pt
- **Step indicators**: 4 barras × 48pt width, 4pt height, 8pt spacing
- **Station badges**: padding 8×12pt, radius 8pt, border 2pt
- **Ticket card**: radius 16pt, shadow medium

---

## 5. Arquitetura Técnica

### 5.1 Stack

```
┌─────────────────────────────────────────┐
│              SwiftUI Views              │
├─────────────────────────────────────────┤
│           ViewModels (MVVM)             │
├──────────┬──────────┬───────────────────┤
│ MapKit   │ SceneKit │ Screen Time API   │
│ (routes) │ (globe)  │ (tunnel mode)     │
├──────────┴──────────┴───────────────────┤
│         SwiftData (persistência)        │
├─────────────────────────────────────────┤
│      UserDefaults (onboarding state)    │
└─────────────────────────────────────────┘
```

### 5.2 Estrutura de Pastas

```
FocusTrain/
├── App/
│   └── FocusTrainApp.swift
├── Features/
│   ├── Onboarding/
│   │   ├── Views/          (10 view files — 1 por tela)
│   │   ├── ViewModels/     (OnboardingViewModel.swift)
│   │   └── Models/         (OnboardingStep, FocusScenario)
│   ├── FocusSession/       (Home, Active, Complete)
│   ├── TrainTicket/        (Card, Detail views + Model)
│   ├── JourneyLog/         (Histórico)
│   └── Settings/
├── Core/
│   ├── DesignSystem/       (Colors, Typography, Components, Animations)
│   ├── Map/                (RailwayMapView, GlobeView, MapStyleManager)
│   ├── ScreenTime/         (TunnelModeManager)
│   └── Storage/            (Persistence, UserDefaults keys)
└── Resources/              (Assets, Fonts, Localizable)
```

---

## 6. Componentes-Chave

### 6.1 Onboarding Scroll Flow (Telas 0–3)

- `ScrollView` vertical com `.scrollTargetBehavior(.paging)`
- Cada seção ocupa tela inteira
- Conteúdo anterior: sobe + fade-out + scale(0.6)
- Botão fixo na parte inferior

### 6.2 Train Ticket Card

- Card branco com sombra, rounded corners 16pt
- Header: Station codes (SPO ➝ RIO) com ícone trem
- Grid: Wagon, Seat, Distance, Date, Boarding
- Divider tracejado
- QR Code gerado via `CoreImage` `CIQRCodeGenerator`
- Background sutil: mapa de pontos da rede ferroviária

### 6.3 Station Badge

- Pill shape amarelo (#F5C518)
- Ícone `tram.fill` + código da estação em monospace bold
- Border 2pt amarela

### 6.4 Glow Text Effect

- `LinearGradient` (gold → emerald → white)
- Shadow layers com `.opacity` animado
- Pulsação contínua `easeInOut(duration: 2).repeatForever`

### 6.5 Railway Route on Map

- `MapPolyline` com coordenadas curvas (waypoints intermediários)
- MapKit dark style (`.imagery(elevation: .flat)`)
- `StationBadge` annotations nos endpoints

### 6.6 Focus Scenario Tag Cloud

- Layout customizado, tags com posições orgânicas
- Cada tag: ícone SF Symbol + nome + cor pastel única
- Rotação aleatória (-15° a +15°)
- Pill shape, animação de tap

### 6.7 Tunnel Mode Circle

- Círculo grande cinza claro centralizado
- Ícone ampulheta+cadeado no centro
- Ícones de apps sociais orbitando ao redor
- Animação: apps fade-out ao ativar

### 6.8 Globe 3D + Map Style Chooser

- SceneKit sphere com textura de mapa ou MapKit Globe
- Grid 2×2 com previews dos estilos
- Seleção com borda branca animated
- Toggle labels com transição do globo

---

## 7. Fases de Desenvolvimento

### Fase 1 — Fundação (Semana 1–2)

- [ ]  Setup projeto Xcode (iOS 17+, SwiftUI)
- [ ]  Design System completo (Colors, Typography, Components)
- [ ]  Componentes base: `CTAButton`, `StepIndicator`, `StationBadge`, `GlowText`
- [ ]  `OnboardingContainerView` com navegação
- [ ]  Persistência (UserDefaults para onboarding state)

### Fase 2 — Onboarding Narrativo (Semana 2–3)

- [ ]  Telas 0–3: Welcome → Engagement → Hyperfocus → Brand Reveal
- [ ]  Scroll vertical com paging + animações fade/scale
- [ ]  Efeito glow na tela de brand reveal
- [ ]  Tela 4: Route Map com MapKit + rota ferroviária curva

### Fase 3 — Ticket & Scenarios (Semana 3–4)

- [ ]  Tela 5: Train Ticket component completo com QR Code
- [ ]  Card stack (ticket traseiro + frontal)
- [ ]  Tela 6: Focus Scenario tag cloud orgânico
- [ ]  Step indicator system

### Fase 4 — Tunnel Mode & Mapa (Semana 4–5)

- [ ]  Telas 7–8: Tunnel Mode com Screen Time API
- [ ]  Animação de apps desaparecendo
- [ ]  Telas 9–11: Globe 3D + Map Style chooser
- [ ]  Toggle labels com animação

### Fase 5 — Final & Polish (Semana 5–6)

- [ ]  Tela 12: Welcome final + Globe fullscreen
- [ ]  Transições entre todas as telas
- [ ]  Haptic feedback
- [ ]  Acessibilidade (VoiceOver, Dynamic Type)

### Fase 6 — Core Features (Semana 6–8)

- [ ]  Home screen com mapa e próxima viagem
- [ ]  Timer de sessão de foco (viagem ativa)
- [ ]  Tela de conclusão (chegada na estação)
- [ ]  Journey Log (histórico)
- [ ]  SwiftData persistência

### Fase 7 — QA & Lançamento (Semana 8–9)

- [ ]  Testes multi-device (iPhone 14–16, SE)
- [ ]  Performance profiling
- [ ]  App Store assets
- [ ]  TestFlight + Submit

---

## 8. Dependências & APIs

| Dependência | Uso |
| --- | --- |
| **MapKit** | Mapas, rotas, globe |
| **SceneKit** | Globe 3D interativo |
| **FamilyControls / Screen Time API** | Tunnel Mode |
| **SwiftData** | Persistência |
| **CoreImage** | QR Codes |
| **Core Haptics** | Feedback tátil |

---

## 9. Notas Importantes

> [!IMPORTANT]
**Screen Time API** requer entitlement `com.apple.developer.family-controls`. Solicitar acesso via Apple Developer portal antes de implementar o Tunnel Mode.
> 

> [!WARNING]
Globe 3D do MapKit disponível apenas iOS 17+. Para versões anteriores, usar SceneKit com textura customizada.
> 

> [!TIP]
Rotas ferroviárias devem usar **polylines curvas** com waypoints intermediários para simular trilhos reais (diferente das linhas retas aéreas).
> 

---

## 10. Estimativa Total

*(seção a preencher quando o cronograma das fases for fechado)*

---

## 11. Identidade Visual — Shinkansen (Bullet Train Moderno)

Decisão: o trem do FocusTrain **não** é vapor/locomotiva antiga. É **bullet train estilo Shinkansen** — futurista, aerodinâmico, silencioso.

### 11.1 Princípios visuais

- **Silhueta**: nariz alongado tipo "pato/agulha" (referência: N700S, ALFA-X), corpo cilíndrico baixo e largo.
- **Paleta do trem**: branco perolado (#F4F6F8) + faixa lateral em **emerald** (#2ECC71) ou **indigo** (#6C7AE0) percorrendo lateralmente. Janelas em vidro escuro contínuo (#0B0F14).
- **Linhas**: minimalismo geométrico, sem rebites/parafusos visíveis. Cantos arredondados grandes.
- **Iluminação**: faróis frontais em LED branco-azulado com pequeno halo (mesmo papel do "glow esmeralda" do brand reveal).
- **Trilho**: dois trilhos finos em perspectiva isométrica baixa; dormentes minimalistas (linhas curtas equidistantes), não madeira marrom.
- **Catenária**: opcional — fina linha cinza acima do trem em telas onde o trem aparece de lado.

### 11.2 SF Symbols / ícones

- Substituir `airplane` por `tram.fill` **em todos os lugares**. Onde a metáfora exige nariz aerodinâmico (loader, marca, splash), usar **asset vetorial customizado** (`shinkansen.nose`, `shinkansen.side`, `shinkansen.front`) — SF Symbol genérico de trem é estilo eléctrico urbano e fere a identidade.
- Estação: `building.2.fill` é genérico demais — desenhar asset `station.shinkansen` (plataforma elevada com cobertura curva).

### 11.3 Animações de marca

- Brand reveal (Tela 3): em vez de "light burst" estático, **streak de motion blur horizontal** atravessando a tela da direita para a esquerda, deixando uma trilha esmeralda que se condensa no logotipo. Duração 1.2s, ease-out.

---

## 12. Sistema de Rotas Procedurais (Procedural Route Generation)

Inspirado no FocusFlight: **qualquer estação pode ser origem ou destino** — não estamos amarrados a malha ferroviária real. Cada sessão de foco gera uma rota nova.

### 12.1 Modelo de dados

```swift
struct Station: Identifiable, Codable {
    let id: UUID
    let code: String          // 3 letras, ex: "SPO", "RIO", "KYO"
    let name: String          // "São Paulo Luz"
    let city: String          // "São Paulo"
    let country: String       // "BR"
    let coordinate: CLLocationCoordinate2D
    let timezone: String
}

struct Route: Identifiable, Codable {
    let id: UUID
    let origin: Station
    let destination: Station
    let distanceKm: Double           // great-circle, depois ajustada
    let estimatedDurationMin: Int    // = focusSessionDuration
    let polyline: [CLLocationCoordinate2D]   // curva gerada
    let scenario: FocusScenario
    let createdAt: Date
}
```

### 12.2 Catálogo de estações

- Iniciar com **~150 estações sementes** distribuídas globalmente, mas com codinomes ferroviários (não copiar IATA). Ex.: `SPO` São Paulo, `RIO` Rio, `KYO` Kyoto, `TYO` Tokyo, `BER` Berlin, `PAR` Paris-Nord, `LDN` London-King's-Cross, `NYC` Grand-Central, `LIS` Lisboa-Oriente.
- Bundled JSON em `Resources/stations.json`. Permite expandir sem update binário (futuramente fetch remoto).

### 12.3 Algoritmo de geração de rota

Quando o usuário toca **Start Journey**:

1. **Origem** = última estação de chegada salva em `UserDefaults` (default = estação mais próxima por `CLLocationManager`, ou `SPO` se sem permissão).
2. **Destino** = sorteio ponderado:
   - 60% chance: estação a 200–800 km (viagens "comutáveis", duração baixa).
   - 30% chance: estação a 800–3000 km (viagem média).
   - 10% chance: estação intercontinental (viagem longa, "trem mítico" — quebra a verossimilhança em prol da fantasia).
   - Excluir estações usadas nas últimas 5 viagens (anti-repetição).
3. **Distância** = great-circle (Haversine) × 1.15 (fator de tortuosidade ferroviária).
4. **Duração** = **input do usuário** (slider 15min–4h). Distância é narrativa, não dirige duração.
5. **Polyline curva** = great-circle samplada em 32 pontos + jitter perpendicular de até ±0.5° em pontos intermediários (sensação de trilhos contornando terreno, não rota aérea reta).

### 12.4 Códigos de estação

3 letras maiúsculas. Não usar códigos IATA reais para evitar associação a aeroportos. Sufixos `-1`, `-2` permitidos para cidades com múltiplas estações (`PAR-N`, `PAR-L`).

### 12.5 Conteúdo do ticket gerado

Campos do Train Ticket são derivados da `Route`:
- **Wagon**: `1 + (route.id.hashValue % 12)` → 1–12
- **Seat**: `(hash % 30 + 1) + ["A","B","C","D","F"].random` → ex.: "12B"
- **Platform**: `(hash % 24 + 1)` → "Plat. 7"
- **Train number**: `"FT-" + (hash % 9000 + 1000)` → ex.: "FT-3471"

Determinístico por rota: o mesmo ticket nunca muda se reaberto.

---

## 13. Telas Pós-Onboarding (App Principal — Telas 13–18 do referencial)

### Tela 13 — Home / Estação Atual

- **Background**: mapa fullscreen no estilo escolhido na Tela 9–11, centrado na **estação atual** (= último destino).
- **Card flutuante topo**: badge da estação atual + cidade + "Currently at" (small label).
- **Bottom sheet (peek state)**:
  - Título: "Ready for your next ride?"
  - Subtítulo: "Choose a scenario and depart."
  - Duration picker (compacto): 25 / 50 / 90 / Custom.
  - Botão grande: **"Start Journey"** (pill, preto).
- **Tab bar inferior**: Home · Journey Log · Settings.

### Tela 14 — Ticket Gerado (Pré-Viagem)

- Aparece em **modal sheet** após Start Journey.
- Rota recém-gerada exibida no formato Train Ticket completo (componente da seção 6.2).
- Status badge: **"BOARDING"** (azul pulsante).
- Botão primário: **"Check In"** (preto).
- Botão secundário: "Generate Another Route" (texto). Limite: 3 re-rolls por dia (anti-loop de procrastinação).

### Tela 15 — Check-In / Sound Picker

- **Título**: "Choose your ambience 🎧"
- **Subtítulo**: "Pick a soundscape for the ride."
- **Grid 2×3** de cards de som (cada card = waveform + nome + ícone):
  - 🚂 **Rail Clatter** — ritmo clássico de trilhos
  - 🌧️ **Rainy Window** — chuva batendo na janela do vagão
  - 🏙️ **Station Ambience** — anúncios distantes, passos
  - 🌲 **Countryside Pass** — vento + pássaros + trem distante
  - 🎶 **Lo-Fi Carriage** — lo-fi + clatter sutil
  - 🔇 **Silent Car** — sem som
- **Toggle**: "Tunnel Mode" (Screen Time) ON/OFF.
- **Botão**: "Depart 🚂" (verde esmeralda).

### Tela 16 — Active Journey (Sessão de Foco em Andamento) ⭐

**Divergência principal vs. FocusFlight:** orientação **horizontal**, paisagem passando, não ascensão vertical.

- **Background**: gradiente do céu adaptado à hora do dia (amanhecer/dia/entardecer/noite).
- **Paisagem (camada média)**: silhuetas de morros/cidades em **parallax** — camadas próximas passam rápido, distantes devagar. Loop infinito.
- **Trilho (camada baixa)**: trilhos em perspectiva passando da direita para a esquerda, dormentes se aproximando rapidamente.
- **Trem (overlay fixo)**: shinkansen visto **de lado**, ocupando ~40% da largura, levemente acima do centro. Não se move horizontalmente; quem se move é a paisagem.
- **HUD superior**:
  - Esquerda: badge origem (ex.: `SPO`) + "Departed 14:02"
  - Direita: badge destino (ex.: `RIO`) + "ETA 14:52"
  - Centro: barra de progresso fina horizontal, com ícone de trem deslizando ao longo dela.
- **HUD inferior**:
  - Centro grande: **timer countdown** mono digital — "00:42:18"
  - Linha abaixo: "248 km remaining · Wagon 3 · Seat 12B"
- **Controles**: tap na tela → revela botões "Pause" e "End Journey Early" com confirmation.
- **Sem notificações**: app silencia push enquanto ativo (Focus Filter integration, iOS 16+).

### Tela 17 — Arrival (Conclusão)

- Background: vista frontal do shinkansen chegando a uma estação iluminada.
- Confete sutil (partículas verdes) + haptic notification success.
- Título: **"You've arrived in [Cidade Destino] 🚂"**
- Stats grid:
  - Distance covered · Focus time · Scenario · Wagon/Seat
- Botão: "Save to Journey Log" (preto).

### Tela 18 — Journey Log

- Lista vertical de tickets passados (cards menores, formato similar ao "card traseiro" da Tela 5).
- Filtros no topo: All · This Week · This Month · By Scenario.
- Header com totalizadores: viagens · distância acumulada · horas focadas.
- Tap em card → ticket fullscreen + opção share.

---

## 14. Biblioteca de Sons Ambiente

Arquivos em `Resources/Sounds/` como `.m4a` (AAC 128kbps, loopable seamless ≥3 min).

| Nome | Arquivo | Descrição | Licença |
| --- | --- | --- | --- |
| Rail Clatter | `rail_clatter.m4a` | Trem em alta velocidade, junções regulares | CC0 / próprio |
| Rainy Window | `rain_window.m4a` | Chuva contra vidro + clatter abafado | CC0 |
| Station Ambience | `station_ambience.m4a` | Murmúrio, passos, anúncios em japonês baixo | CC0 |
| Countryside Pass | `countryside.m4a` | Vento, pássaros, trem ao longe | CC0 |
| Lo-Fi Carriage | `lofi_carriage.m4a` | Lo-fi loop + clatter sutil | royalty-free |
| Silent Car | — | Nenhum áudio reproduzido | — |

- Player: `AVAudioEngine` com `AVAudioPlayerNode` em loop.
- Volume: slider único no Settings.
- Mistura com música externa: `.duckOthers` por padrão (Spotify/Apple Music continua tocando, abaixado).

---

## 15. Divergências Explícitas vs. FocusFlight

Pontos onde o FocusTrain **intencionalmente diverge** da referência (não são apenas renames):

1. **Active screen horizontal** com paisagem em parallax (FocusFlight é vertical, avião sobe).
2. **Ticket com Platform/Wagon/Seat** (FocusFlight tem Seat aviation-style — "21A").
3. **Polyline curva com jitter** (FocusFlight usa great-circle reta de avião).
4. **Re-roll de rota limitado** a 3/dia (FocusFlight não tem; previne procrastinação).
5. **Estações com codinomes próprios**, não IATA (evita confusão visual com aeroporto).
6. **Sons temáticos de trem** (FocusFlight tem motor de avião + chuva genérica).
7. **Asset custom para trem** em vez do `tram.fill` SF Symbol (que parece bonde urbano, não shinkansen).
8. **Long-haul intercontinental quebra realismo** propositalmente (10% das viagens) — fantasia > geografia.

---

## 16. Próximos Passos

Este documento é o **spec base**. Antes de codar:

1. Validar com o usuário se as Telas 13–18 estão alinhadas com a expectativa.
2. Definir idioma de UI: **EN** (segue referencial) ou **PT-BR** (segue o usuário). Spec atual usa EN.
3. Aprovar paleta Shinkansen (seção 11) ou ajustar faixa lateral (emerald vs indigo).
4. Confirmar o catálogo inicial de 150 estações antes de gerar `stations.json`.
