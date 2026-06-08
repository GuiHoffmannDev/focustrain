# Badge de código no destino selecionado (picker de duração)

**Data:** 2026-06-08
**Tela:** `DurationPickerView` → `DestinationMapView` (picker de cidade/tempo da sessão de foco)

## Problema

No picker de duração o usuário escolhe uma estação no mapa, mas o pin
selecionado é só um disco com o glifo de trem — não há confirmação textual de
*para onde* ele está indo. A referência (apps de voo) mostra um badge com ícone
+ código da cidade (ex. `MHD`) destacado no destino, dando confirmação visual.

## Objetivo

Quando uma estação está selecionada, exibir seu **código de 3 letras** (ex.
`ROD` de Rodeo) num badge em formato de **pill** com o ícone de trem, em accent,
sobre a coordenada da estação. Confirmação visual de "para onde estou indo".

## Escopo

- **Só o destino selecionado** vira pill. Os demais pins (ghost/solid) ficam
  exatamente como hoje. (Com 9–12 estações no anel, mostrar código em todas
  poluiria.)
- Um único arquivo afetado: `FocusTrain/Features/FocusSession/Views/Components/DestinationMapView.swift`.
- Aditivo: nenhum arquivo novo, nenhuma mudança de modelo de dados além de um
  campo a mais na annotation.

Fora de escopo: linha de rota origem→destino, redesenho dos demais estados,
mudar o anel/câmera, código nos cards da strip.

## Design

### Dados

- `StationAnnotation` ganha um campo `let code: String`.
- Em `DestinationMapView.makeUIView`, ao criar cada `StationAnnotation`, passar
  `code: dest.code` junto do `title: dest.city`. O código já existe
  (`Destination.code` → `Station.code`, as 3 primeiras maiúsculas da cidade).

### View do pin (`StationAnnotationView`)

A mesma view passa a renderizar **duas formas** e alterna entre elas conforme o
estado, porque a seleção muda quando o usuário arrasta a régua (um índice
vira/deixa de ser selecionado e a annotation é reutilizada):

- **ghost / solid:** disco atual (glifo de trem), sem alteração de aparência.
- **selected:** **pill** horizontal = `tram.fill` + label do código lado a lado.

Detalhes da pill:

- **Fundo:** brass (`E0A458`) — o accent que o estado selecionado já usa nesta
  tela (borda + glow + pulse). Coerente com a composição atual e próximo do
  dourado da referência. *Não* usa o branco do brand accent global, porque aqui
  o accent de seleção já é brass.
- **Conteúdo:** ícone + código em tom **escuro** sobre o brass (igual à
  referência), código em fonte bold (~13pt).
- **Largura dinâmica:** acomoda 3 letras ou variações (`ORG`, `SAO`). Cápsula
  com `cornerRadius = altura/2`.
- **Âncora:** centralizada na coordenada da estação (ajustar `frame` e
  `centerOffset` ao trocar de forma, mantendo o centro sobre o ponto).
- **Glow/pulse:** preserva o glow do selecionado; o `pulse` é adaptado para a
  forma de cápsula (frame + cornerRadius da pill) para manter o "vivo" da tela.

### Morph de estado

`apply(state:)` passa a alternar disco↔pill: mostra/oculta o subview certo,
redimensiona `frame`/`centerOffset` e ajusta o `pulse`. A transição reaproveita
o spring/escala já usado hoje (o `updateUIView` chama `view.apply(state:)` a cada
mudança de `selectedIndex`). Ao deselecionar, a pill encolhe de volta pro disco.

### Acessibilidade

Sem mudança: `applyA11y` continua usando `dest.city` + `dest.minutes`. O código
é reforço visual, não um novo elemento de a11y.

## Critério de sucesso

- Ao abrir o picker, o destino atual aparece como pill brass com `tram.fill` +
  código (ex. `ROD`), centrada sobre a estação.
- Arrastar a régua move a pill para a nova estação; a anterior volta a disco,
  com a transição suave existente.
- Ghost e solid inalterados. Sem regressão de seleção por toque, pan ou zoom.
