# Thumb de metade arredondada na pílula de câmera (SessionView)

**Data:** 2026-06-10
**Tela:** `SessionView` → pílula de modo de câmera (fit route / center train)
**Referência visual:** `assets/2026-06-10-camera-pill-thumb-reference-1.jpg` e `-2.jpg`

## Problema

A pílula de câmera é um seletor de duas posições, mas o estado ativo hoje é um
círculo translúcido atrás do glifo (`controlActiveTint`) — o mesmo visual de um
toggle avulso (ex. túnel). Não comunica "segmento selecionado de um seletor",
e a referência mostra um tratamento muito mais claro: o segmento ativo é um
bloco sólido que abraça a curvatura da cápsula.

## Objetivo

O segmento selecionado vira um **thumb sólido** com cantos assimétricos:

- **Seleção no TOPO:** cantos superiores totalmente arredondados, concêntricos
  à curvatura interna da cápsula; cantos inferiores com raio pequeno, criando a
  linha de divisão horizontal no meio do componente.
- **Seleção na BASE:** espelhado — cantos superiores com raio pequeno no meio,
  inferiores abraçando a base da cápsula.

Ao trocar a seleção o thumb **desliza** entre topo e base e os cantos "viram"
junto (morph animado dos raios).

## Escopo

- **Um componente novo:** `SessionSegmentedPill` em
  `Core/DesignSystem/Components/`, autocontido (cápsula glass + thumb + dois
  botões de glifo). Aparece automaticamente no target (synced file groups).
- **Um call site:** `SessionView.runningRightColumn` troca o
  `SessionControlPill { 2× SessionControlButton }` pelo componente novo.
- **Um token novo** em `Colors.swift` (ver Cores).
- `SessionControlPill` e `SessionControlButton` **não mudam** — continuam
  servindo os botões avulsos (pause, música, mapa, túnel) e o par pause/música.

Fora de escopo: mudar ícones, hierarquia ou posição dos controles; os demais
botões da coluna; qualquer outro uso de pílula no app.

## Design

### Geometria

Métricas derivadas das existentes (glifo 48pt, padding 6):

- Cápsula: largura 60, raio externo 30.
- Thumb: inset 6pt da borda da cápsula → largura 48.
- Altura do thumb: da borda interna (y=6) até o centro vertical da pílula menos
  meio-gap (~2pt) — o bloco termina visualmente na metade, como na referência.
- **Cantos externos:** raio 24 (raio da cápsula − inset, concêntrico).
- **Cantos internos:** raio 8.
- Forma: `UnevenRoundedRectangle` (raios animáveis nativamente).

### Animação

Um único thumb num `ZStack` atrás dos glifos, alinhado `.top`/`.bottom`
conforme a seleção. Posição e raios animam com o spring já usado no toggle de
câmera (`response 0.4, dampingFraction 0.82`). Sem `matchedGeometryEffect`
(distorce o morph dos cantos).

### Cores

- **Thumb:** sólido, novo token `controlThumb = Color(light: 0x1A1A2E, dark:
  0xFFFFFF)` — a versão opaca de `controlActiveTint`. Sólido é intencional
  (fiel à referência); os toggles avulsos continuam translúcidos.
- **Glifo selecionado:** `controlActiveGlyph` (branco no light, ink no dark).
- **Glifo idle:** `textPrimary`, como hoje.
- A cápsula mantém o Liquid Glass real (`ftGlassCapsule(liquid: true)`),
  conforme a regra de glass seletivo do DS.

### API

```swift
SessionSegmentedPill(
    selection: $index,            // 0 = topo, 1 = base
    options: [
        .init(systemName: "point.topleft.down.to.point.bottomright.curvepath",
              accessibilityLabel: ..., accessibilityValue: ...),
        .init(systemName: "scope", ...)
    ]
)
```

Desenhado para duas opções (o conceito de "metade arredondada" só existe com
duas metades). O haptic light no toque permanece no call site, junto do
`withAnimation` que já embala a troca de `cameraMode`.

### Acessibilidade

Sem mudança de semântica: cada segmento continua um botão com o mesmo
`accessibilityLabel` (`session.fit.route` / `session.center.train`) e value
`on`/`off`. O thumb é decorativo.

## Critério de sucesso

- No light mode, pílula clara com bloco ink sólido; no dark, bloco branco com
  glifo ink — em ambos o bloco abraça a curvatura da cápsula no lado externo e
  forma a linha de divisão reta (raio 8) no meio.
- Tocar o segmento idle desliza o thumb para o outro lado com morph suave dos
  cantos; glifos trocam de cor em sincronia.
- Pause, música, mapa e túnel visualmente intactos; VoiceOver lê os mesmos
  labels/values de hoje.
- Previews light/dark no arquivo do componente, no padrão do DS.
