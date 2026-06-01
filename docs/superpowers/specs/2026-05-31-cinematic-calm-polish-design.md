# FocusTrain — Premium Polish: Cinematic Calm

**Data:** 2026-05-31
**Fase:** Premium Polish (pós Phase 3 / core focus-ride loop)
**Direção:** Cinematic Calm — a jornada como experiência meditativa de primeira classe.

---

## 1. Visão geral

Esta fase aplica uma camada de acabamento "Cinematic Calm" sobre o app já funcional, **sem reestruturar telas que o usuário já gosta**. O princípio que governa tudo: *somar profundidade, calma e cuidado por cima das composições existentes* — serif refinada em momentos hero, movimento lento e gracioso, materiais/profundidade sutis, glow brass refinado e háptico semântico. Loops de áudio ambiente entram como motor agora, som real depois.

### Princípios de design
- **Preservar composições fortes.** Telas que o usuário aprovou (Live ride) mudam só no *feel*, nunca no layout.
- **Serif só em momentos hero.** New York (`design: .serif`, built-in, zero bundling) em títulos celebratórios; SF/mono permanece para UI, dados e o ticket.
- **Movimento "settle".** Molas mais lentas/graciosas (~response 0.6 / damping 0.9) substituem o ritmo atual (0.5/0.85) nos momentos de respiro.
- **YAGNI.** Nada de dashboards, nada de elementos novos onde um retoque resolve.

### Restrições invioláveis
- **Nunca editar `.pbxproj`.** Arquivos novos só são *dropados* nas pastas (PBXFileSystemSynchronizedRootGroup). Avisos stale do SourceKit ("Cannot find FT in scope") em arquivos novos são esperados — ignorar, confiar no build.
- **Toda cópia user-facing via `Localizable.strings`** (`NSLocalizedString`), PT-BR como base.
- **Accent é BRANCO** (`FT.Palette.brandRail = #FFFFFF`). Brass (`#E0A458`) é o calor secundário.
- **Verificar cada incremento** com `xcodebuild` no simulador iPhone 17 Pro.
- **Um incremento totalmente animado por vez**, em ordem Foundation-up.

---

## 2. Foundation (base transversal)

Cinco tokens/módulos que todas as seções consomem. Construídos primeiro.

### 2.1 Tipografia serif-hero (Option A)
- Helper em `FT.Typography` que retorna `Font.system(size:weight:design: .serif)` para momentos hero.
- **Onde entra:** título da Arrival ("Você chegou"), saudação da Home, título do Compose, linhas celebratórias grandes.
- **Onde NÃO entra:** countdown, campos do ticket, dados, qualquer número (permanecem SF/mono para leitura precisa). **Nada de serif na Live ride.**

### 2.2 Linguagem de movimento "settle"
- Constante de mola compartilhada: `response ≈ 0.6`, `dampingFraction ≈ 0.9` (mais calma que a atual 0.5/0.85).
- Reveals escalonados (stagger) nas entradas de tela.
- `.contentTransition(.numericText())` em todo número que muda (streak, countdown, stats).

### 2.3 Profundidade & materiais
- Painéis em `.ultraThinMaterial` onde hoje há preenchimento sólido leve.
- Uma vinheta top-down sutil reutilizável.
- Um único token de sombra de elevação.

### 2.4 Modificador de glow brass refinado
- Um `ViewModifier` reutilizável que produz o glow brass suave (radial, baixa opacidade) — substitui glows ad-hoc espalhados.
- Usado no 🔥 da streak, no estado "on" de controles, e no momento túnel.

### 2.5 Háptico semântico
- Conjunto nomeado: `.soft` (toques leves), `.rigid` (compromissos: partida/chegada), `.success` (celebração da chegada).
- Centralizado num helper para consistência.

---

## 3. Live Ride (SessionView) — **feel-only**

> Decisão do usuário: o layout atual é preferido ("achei mais bonito"). **Sem reestruturação, sem novos elementos on-screen, sem serif.** Mantém badges TYO→KYO, o `24:08` grande/bold, e os toggles sólidos exatamente como estão.

Aplicar apenas polish invisível:
- **Câmera settle.** O follow do trem usa a mola lenta/graciosa — desliza para a posição em vez de saltar.
- **Háptico consistente.** `.rigid` na partida; toques `.soft` nos toggles; handoff `.success`/`.rigid` na chegada.
- **Glow brass afinado.** Ajuste fino do glow existente via o modificador da Foundation — mais suave, mais coeso. Sem aumentar área nem adicionar elementos.
- **Soundscape.** O toggle "Vagão silencioso" passa a controlar o mudo do `SoundscapeEngine` (sem UI nova).

---

## 4. Home & Compose

Aplicar a base **somando sobre o layout atual**, sem reestruturar. O herói de streak de 88pt em SF permanece intacto.

### 4.1 Home — quatro movimentos
1. **Saudação serif.** Uma linha em New York no topo, sob o wordmark RailFocus (ex.: "Boa noite", dependente da hora). Momento hero serif da Home. Wordmark permanece.
2. **Streak intacto.** O número 88pt em SF fica exatamente como está; só o 🔥 ganha o glow brass refinado.
3. **Linha de stats tecida (3 stats).** Discreta, sob a streak: **Jornadas · Tempo de foco · km percorridos**. A distância é o toque on-theme de trem. Números mono com `.numericText()`. É *lightweight stats*, não dashboard.
   - Derivados de `@Query` em `Journey`: contagem total; soma de durações; soma das distâncias das rotas.
   - Toda label via `Localizable.strings`.
4. **Profundidade sutil.** Linhas "Recentes" ganham material leve + glow; entradas usam a mola settle escalonada.

### 4.2 Compose — dois toques (estrutura idêntica)
- O **título** "Componha sua jornada" vira serif New York (momento hero).
- Chips de duração/cenário e o ticket brass ganham o glow refinado + mola settle.
- **Inalterado:** estrutura geral, reroll, ScenarioChips, depart bar, TrainTicketCard.

---

## 5. Ambient Soundscapes

Motor completo + mapeamento + mix de túnel agora; **fallback = silêncio gracioso** (sem som até os loops reais chegarem). Três unidades isoladas.

### 5.1 `SoundscapeEngine` (`@Observable`)
- Envolve `AVAudioEngine` com camadas em loop e mix de ganho independente: **base** (ambiente do cenário) + **trilho** (textura rítmica do trem) + **bus de túnel** opcional.
- `AVAudioSession` categoria `.playback` com **`.mixWithOthers`** — respeita música/podcast do usuário, nunca interrompe.
- Fades suaves (curvas settle ~1.5–2s): `fadeIn` na partida, `fadeOut` na chegada, crossfade no túnel. Nunca cortes secos.
- API: `start(for: scenario)`, `enterTunnel()`, `exitTunnel()`, `stop()`, `setMuted(_:)`.
- **Detecção de assets ausentes:** sem arquivo → degrada para silêncio sem erro/crash. Toda a cadeia de mix/fade permanece cabeada e exercitável.

### 5.2 `ScenarioSoundscape` (mapeamento puro)
- Mapeia cada `FocusScenario` (forest/mountain/coast/desert/meadow) → nomes de arquivo de loop + níveis de mix default. Ex.: `forest → (base: "amb_forest" @0.7, rail: "rail_clack" @0.5)`.
- Tabela de dados pura, **sem dependência de AVFoundation**, testável isoladamente.

### 5.3 `TunnelMix` (o momento túnel)
- No marco de túnel (trecho fixo no meio da viagem): abafa a base, sobe rumble/reverb do trilho (o *whoosh* fechado), reabre na saída. Efeito cinematográfico curto.
- Reutiliza o glow brass da Foundation para o acompanhamento visual, se aplicável (sem novo elemento permanente).

### 5.4 Controle
- O toggle **"Vagão silencioso"** existente na Live ride é o controle de mudo — `setMuted(_:)`. **Sem UI nova.**

### 5.5 Entrega de assets (depois)
- Loops reais (`.caf`/`.m4a`) são dropados numa pasta de recursos por nome esperado pelo `ScenarioSoundscape`. Sem mudança de código necessária quando chegarem.

---

## 6. Fronteiras & retoques de consistência

### 6.1 Diferido (fora desta fase)
- **Live Activity / Dynamic Island** — exige novo target de extensão + entitlements (colide com "nunca editar .pbxproj"). Fase própria no futuro.
- **Tunnel Mode real com Family Controls** (bloqueio de apps) — exige novo target + entitlement de Screen Time. O "túnel" desta fase é o momento sonoro/visual (Seção 5), não bloqueio de sistema.

### 6.2 Telas não priorizadas — só consistência, sem redesign
- **Arrival.** Recebe o serif hero "Você chegou" (Option A) + mola settle + háptico `.success` na celebração. Selo brass existente mantido. Sem reestruturar.
- **History.** Só tokens da base (material leve nas linhas, mola settle nas entradas) para não destoar da Home polida. Nenhum elemento novo.

---

## 7. Ordem de implementação (Foundation-up)

Cada passo é um incremento totalmente animado, verificado com `xcodebuild` no iPhone 17 Pro antes do próximo.

1. **Foundation** — tipografia serif-hero; molas settle; profundidade/materiais; modificador de glow brass; háptico semântico.
2. **Live ride (feel-only)** — câmera settle, háptico, afinação do glow.
3. **Home & Compose** — saudação serif, glow no 🔥, linha de 3 stats, profundidade; serif no título do Compose + glow/settle nos chips e ticket.
4. **Soundscapes** — `ScenarioSoundscape` → `SoundscapeEngine` → `TunnelMix` → cabeamento do toggle "Vagão silencioso"; fallback silêncio gracioso.
5. **Consistência** — Arrival (serif hero + háptico) e History (tokens da base).

---

## 8. Critérios de sucesso

- Nenhuma tela que o usuário gosta é reestruturada; mudanças na Live ride são puramente de feel.
- Serif aparece apenas em momentos hero (Arrival, Home, título do Compose); números permanecem SF/mono.
- Home ganha saudação serif + 3 stats sem virar dashboard.
- Motor de soundscape totalmente cabeado e silencioso-por-padrão até assets reais; mixa com áudio do usuário; mudo via "Vagão silencioso".
- Zero edição de `.pbxproj`; toda cópia localizada em PT-BR; accent branco preservado.
- Cada incremento compila limpo via `xcodebuild`.
