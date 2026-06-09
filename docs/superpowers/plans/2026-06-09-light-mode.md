# Light Mode no FocusTrain (seguindo a aparência do sistema)

## Contexto

O app é 100% dark-mode-only: dark forçado em 5 pontos (`.preferredColorScheme(.dark)` ×3 + `overrideUserInterfaceStyle = .dark` nos mapas ×2) e `FT.Palette` (Colors.swift) com hex fixos. O objetivo é suportar Light mode seguindo a aparência do dispositivo (sem toggle in-app), com **Dark permanecendo pixel-por-pixel idêntico ao atual**. No Light, o mapa monocromático fica branco com cinzas — sai quase de graça, pois monochrome = `MKStandardMapConfiguration(emphasisStyle: .muted)` + dessaturação por blend, que funciona nos dois esquemas.

**Estado:** branch `feat/cities-sqlite-clean-home`, working tree limpo em `a055e90`. Criar branch `feat/light-mode` a partir daqui.

## Decisões do usuário

1. **Abordagem:** tokens dinâmicos em código — `FT.Palette` continua a única fonte; cada token vira par light/dark via `UIColor` dynamic provider. Sem asset catalog.
2. **Estrelas (StarsBackground):** somem no Light (só renderizam em dark).
3. **Acento `brandRail`/`railLine` no Light:** cinza escuro `#333333`.
4. **Fundo no Light:** off-white `#F5F5F7` (`bgPrimary`); `bgElevated` light = `#FFFFFF`.

---

## Fase 1 — Fundação: tokens dinâmicos em `Colors.swift`

Único arquivo: `FocusTrain/Core/DesignSystem/Colors.swift`. Nenhum call site muda; no-op visual (dark ainda forçado e valores dark = hex atuais).

**Helper:**
```swift
extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) { ... }
}
extension Color {
    /// Token dinâmico light/dark via UIColor dynamic provider.
    init(light: UInt32, lightAlpha: CGFloat = 1,
         dark: UInt32,  darkAlpha: CGFloat = 1) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: dark,  alpha: darkAlpha)
                : UIColor(hex: light, alpha: lightAlpha)
        })
    }
}
```

**Tokens que viram dinâmicos** (dark = hex atual, byte a byte):

| Token | Dark (atual) | Light (novo) |
|---|---|---|
| `bgPrimary` | `0x000000` | `0xF5F5F7` |
| `bgElevated` | `0x0F1729` | `0xFFFFFF` |
| `brandRail` / `railLine` | `0xFFFFFF` | `0x333333` |
| `textPrimary` | `0xFFFFFF` | `0x1A1A1A` |
| `textSecondary` | `0x9CA3AF` | `0x5B616B` |
| `textMuted` | `0x6B7280` | `0x8E939B` |
| `gray800` (bg SessionPauseMenu) | `0x1E1E1E` | `0xE5E6E8` |

**Permanecem estáticos:** `black`, `white` (primitivos absolutos), `brandBrass`, `ink`, `surfaceLight`, `success`, `emerald`, `indigo`, `gray100`, `gray400`, `greenDark`, `Scenario.*` (pastels funcionam nos 2 esquemas com fg `ink`).

**Tokens novos:**

| Token | Dark | Light | Substitui |
|---|---|---|---|
| `strokeHairline` | white 8% | black 10% | rim idle do glass, dividers 6–8% |
| `strokeCard` | white 10% | black 8% | stroke do FTGlassCardButton |
| `scrim` | `0x000000` | `0xF5F5F7` | vinhetas/gradientes (= bgPrimary) |
| `shadowSoft` | black 40% | black 15% | sombras de chrome |
| `controlActiveTint` | white 75% | ink 75% | tint do glass ativo |
| `controlActiveGlyph` | ink | white | glyph sobre controle ativo + fg do CTA primary |
| `chipSelectedTint` | white 75% | ink 75% | filtros History/Trends |
| `chipSelectedFg` | black | white | fg dos filtros (hoje `.black` exato) |

**Pegadinhas** (documentar no próprio arquivo): `.opacity()` sobre cor dinâmica funciona (usar quando o alpha é igual nos 2 esquemas; embutir no provider quando difere); nunca extrair `cgColor`/`UIColor(Color)` de token dinâmico (congela); `MKOverlayRenderer`/`CALayer`/`UIImage` não aceitam dynamic provider de forma confiável → cores estáticas resolvidas por flag + re-aplicação no flip (Fase 4).

## Fase 2 — Componentes do DS adaptativos (ainda no-op visual)

Respeita a tabela de estados do spec `docs/superpowers/specs/2026-06-09-liquid-glass-ds-consolidation-design.md`, tornando-a adaptativa. `glassEffect(.regular)` e `.ultraThinMaterial` já adaptam sozinhos.

- `Core/DesignSystem/Components/FTGlass.swift`: `ftGlassSelectionStroke` idle `white.opacity(0.08)` → `strokeHairline` (selected `brandRail 0.85` fica — adaptativo de graça); `FTGlassCardButton` fg `white` → `textPrimary`, stroke `white 0.10` → `strokeCard`.
- `SessionControlButton.swift`: glyph `active ? ink : white` → `controlActiveGlyph : textPrimary`; tints `white.opacity(0.75)` → `controlActiveTint`.
- `CTAButton.swift`: primary fg → `controlActiveGlyph`; secondary/ghost → `textPrimary`; `FTGlassIconButton` fg default → `textPrimary`.
- `SessionControlPill.swift`, `SessionEllipsisButton.swift`, `SoundMasterPill.swift`, `AirPlayButton.swift`: glyphs `white` → `textPrimary`.

## Fase 3 — Remover o dark forçado

1. `FocusTrain/ContentView.swift:14` — remover `.preferredColorScheme(.dark)`
2. `Features/Onboarding/Views/OnboardingContainerView.swift:23` — idem
3. `Features/TrainTicket/Views/CustomFocusModeSheet.swift:63` — idem
4. `Core/Map/GlobeHomeView.swift:27` — remover `map.overrideUserInterfaceStyle = .dark`
5. `Features/FocusSession/Views/Components/DestinationMapView.swift:33` — idem
6. **Estrelas:** em `HomeView.swift:72-74`, envolver `StarsBackground()` em `if colorScheme == .dark` (gate no call site; só usado aqui).

Não há `UIUserInterfaceStyle` no Info.plist. Em dark, nada muda; em light o app abre ainda com fundos pretos (migram na Fase 5).

## Fase 4 — Mapa: chrome estilo × esquema

**Nuance central:** terra/satellite têm imagery escura nos DOIS esquemas; chrome `#333` sumiria sobre satélite no Light.

**Arquivo novo** `Core/Map/MapChrome.swift` (synced group — entra no target sozinho; **não tocar project.pbxproj**):

```swift
extension MapStyle {
    /// Imagery escura nos dois esquemas → chrome claro sempre.
    func usesDarkChrome(for scheme: ColorScheme) -> Bool {
        scheme == .dark || self == .terra || self == .satellite
    }
}
/// Cores UIKit do chrome desenhado DENTRO dos mapas (renderers/annotations/UIImage).
/// Estáticas por construção; re-aplicadas no flip de esquema.
struct MapChromeColors { static let dark = ...; static let light = ... }
```

- `MapChromeColors.dark` = valores atuais exatos (routeLine white, ring white 0.5, pin borders white…); `.light` = `#333`/`#1A1A1A`, ghost `#333 0.4`, trainGlow black 0.25. Pill brass do `StationAnnotationView` e capsule do trem ficam.
- Remover a var morta `needsDimmingOverlay` (zero call sites — confirmado).
- **Lado UIKit** (`RouteMapView`, `DestinationMapView`, `JourneyMapView`): adicionar `@Environment(\.colorScheme)` no representable (faz `updateUIView` rodar na troca); guardar `appliedDarkChrome` no Coordinator; no flip, re-adicionar overlay ativo (renderer novo com a cor certa), re-setar UIImages de endpoints/origin dots e re-estilizar `TrainAnnotationView` (CGColor não é dinâmico). `DestinationMapView.applyRing` já recria o `MKCircle`; `JourneyMapView.reload` já recria tudo.
- **Lado SwiftUI** (chrome sobre o mapa): `let darkChrome = style.usesDarkChrome(for: colorScheme)` decide scrim (`black` vs `scrim`) e texto (`white` vs `textPrimary`) em: `SessionView` (scrims, overlay pause, pausedIndicator, `.background` → `bgPrimary`), `SessionMetricTile` (novo `onDarkBackdrop: Bool = true`), `DurationPickerView`, `JourneyMapScreen` (sempre monochrome → só esquema), `HomeView` (vinhetas + PulsingPin; light+satellite: avaliar a olho, item de polish). `SessionTitleLabel` não tem call sites no app (só previews) — TODO, não bloqueia.
- `MapStyleSelector.swift`: swatch mono → `[Color(light: 0xEEEEEE, dark: 0x222222), Color(light: 0xBBBBBB, dark: 0x555555)]`; ícone `map` sobre o swatch mono vira par dinâmico.
- **Dessaturação monochrome: não tocar** (HomeView blend `.saturation`, SessionView `.saturation(0)`, DestinationMapView `saturationBlendMode`) — dessaturar tiles claros já produz o branco-com-cinzas desejado.

## Fase 5 — Varredura por tela

**Padrões mecânicos** (dark resolve para o hex atual em todos):

| Padrão atual | Vira | Onde |
|---|---|---|
| `FT.Palette.black.ignoresSafeArea()` (fundo) | `bgPrimary` | HomeView, DurationPicker, BoardingPass, JourneyMapScreen, CityPicker, Onboarding, SeatPicker, Arrival, SessionView:135 |
| Vinheta `black.opacity(x)` fora de mapa | `scrim.opacity(x)` | HistoryView:69, TrendsSheet:72, SessionPauseMenu:23, SeatPickerView:153 |
| Dividers/strokes `white.opacity(0.06–0.18)` | `strokeHairline`/`strokeCard` | SettingsSheet (~12×), CityPicker, TrendsSheet, AmbientSoundCard, HomeView:178 |
| Texto `FT.Palette.white` semântico | `textPrimary` | SettingsSheet, TrendsSheet, HistoryView, SeatPicker, PremiumDiscountPill, JourneyMapScreen… |
| `shadow(.black.opacity(0.4))` | `shadowSoft` | SessionMetricTile, SessionView:337 |
| Chip selecionado white 0.75 + fg `.black` | `chipSelectedTint`/`chipSelectedFg` | HistoryView FilterChip, TrendsSheet |

**Política "objeto de papel/físico" — aparência IGUAL nos 2 esquemas (pinar absolutos):**
- `TrainTicketCard`, `TicketBodyView`, `TicketStubView`: usos de `brandRail` viram `FT.Palette.white` absoluto (senão o ticket muda no light); resto já é absoluto (ink/brass/surfaceLight).
- `PrinterSlotView`/`TearableTicketView`/`DotMatrixMapView`: já absolutos — não tocar.
- `TunnelHero`: túnel é escuro nos 2 esquemas — manter `black` e pinar `brandRail`→`white` absoluto (5 usos).
- `GiveUpHoldRow`: `blendMode(.difference)` auto-contido — não tocar.
- `SettingsSheet` SubscribeBanner (brass): textos/strokes ficam absolutos (estão sobre brass).
- `TimeRulerView`: é chrome sobre mapa — ticks/labels derivam da cor de chrome (F4) com as mesmas opacities.
- `GlowText`: branco central do gradiente → `textPrimary`.

**Ordem:** 1. HomeView → 2. SessionView + componentes (PauseMenu, AmbientSoundCard…) → 3. DurationPicker + TimeRuler + DestinationCardStrip → 4. SettingsSheet → 5. History + Trends + JourneyMapScreen → 6. Onboarding + CityPicker → 7. BoardingPass + SeatPicker + Arrival. Um commit por grupo; conferir dark vs. baseline a cada um.

## Fase 6 — Polish

- Troca de esquema ao vivo (Settings iOS / `simctl`): tokens re-resolvem; tiles do MapKit re-renderizam via trait; chrome custom re-aplica via F4.2. Testar com Session rodando e DurationPicker aberto.
- `glassEffect` tint dinâmico: se não re-resolver ao vivo, fallback = resolver tint via `@Environment(\.colorScheme)` no componente.
- Pastels Scenario como fg sobre glass claro: se lavarem, escurecer só os fgs 10–15% (não os tints de fundo). Decidir a olho.
- Previews `.preferredColorScheme(.light)` nos componentes-chave (FTGlass, SessionControlButton, TrainTicketCard).
- Salvar spec/plano no repo: `docs/superpowers/specs/2026-06-09-light-mode-design.md` + `docs/superpowers/plans/2026-06-09-light-mode.md` (convenção do repo).

## Verificação

1. **Build por fase:** `xcodebuild -project FocusTrain.xcodeproj -scheme FocusTrain -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build CODE_SIGNING_ALLOWED=NO`; `swift test` (Tests/CitiesHarness) no fim.
2. **Baseline dark (Fase 0):** antes de tudo, screenshots dark de todas as telas (`xcrun simctl ui booted appearance dark` + `simctl io booted screenshot`); ao fim, re-capturar e comparar — **qualquer delta em dark = bug**.
3. **Light:** `xcrun simctl ui booted appearance light`; percorrer todas as telas; nas telas com mapa, matriz 4 estilos × 2 esquemas (atenção a light+terra/satellite: chrome branco + scrims pretos sobre imagery escura).
4. **Troca ao vivo:** alternar appearance com Home/Session/DurationPicker abertos; conferir linha do trilho, pins, anel, desat e tint do glass atualizando.

## Riscos

| Risco | Mitigação |
|---|---|
| Delta acidental no dark (`white`→`textPrimary` onde era estrutural) | Valores dark = hex atuais; diff de screenshots; exceções explícitas (papel, brass, túnel, difference) |
| Chrome UIKit não atualizar no flip | `@Environment(\.colorScheme)` no representable + `appliedDarkChrome` + re-add de overlays/imagens |
| Light+terra/satellite ilegível | `usesDarkChrome` força chrome claro nesses estilos em qualquer esquema |

**Arquivos críticos:** `Core/DesignSystem/Colors.swift`, `Core/DesignSystem/Components/FTGlass.swift`, `Core/Map/MapStyle+MapKit.swift` (+ novo `Core/Map/MapChrome.swift`), `Core/Map/RouteMapView.swift`, `Features/FocusSession/Views/SessionView.swift`, `Features/Settings/Views/SettingsSheet.swift`.
