# RailFocus — PRD & Design System

**App de foco profundo com a metáfora de viagens de trem**
Inspirado na arquitetura de UX do FocusFlight — adaptado para ferrovias.

`v1.0` • iOS-first (SwiftUI) • Mercado: Brasil + Global

---

## Índice

1. [Visão Geral do Produto](#1-visão-geral-do-produto)
2. [Design System](#2-design-system)
3. [Fluxo de Onboarding (tela a tela)](#3-fluxo-de-onboarding-tela-a-tela)
4. [Telas Principais do App (pós-onboarding)](#4-telas-principais-do-app-pós-onboarding)
5. [Escopo de Funcionalidades](#5-escopo-de-funcionalidades)
6. [Stack Técnica Sugerida](#6-stack-técnica-sugerida)

---

## 1. Visão Geral do Produto

RailFocus é um aplicativo de produtividade e foco profundo que transforma cada sessão de concentração em uma viagem de trem. Onde o FocusFlight usa a metáfora de voos (decolagem, rota aérea, pouso, boarding pass), o RailFocus usa a malha ferroviária: a sessão de foco é uma jornada de trem entre duas estações, com partida, trajeto pelos trilhos, paradas e chegada ao destino.

A premissa central é idêntica à do FocusFlight em estrutura e qualidade de experiência, porém com a identidade visual e narrativa completamente reconstruídas em torno de ferrovias — estações, bilhetes (tickets), trilhos, plataformas e o mapa da malha ferroviária.

### 1.1 Conceito-chave (a metáfora)

| Conceito | FocusFlight (original) | RailFocus (novo) |
|---|---|---|
| Sessão de foco | Um voo | Uma viagem de trem |
| Início | Decolagem / takeoff | Partida da estação |
| Trajeto | Rota aérea no mapa | Trilho pela malha ferroviária |
| Fim | Pouso / touchdown | Chegada ao destino |
| Comprovante | Boarding Pass (LHR→CDG) | Train Ticket (SP→RJ) |
| Códigos de ponto | IATA (LHR, CDG) | Sigla de estação (LUZ, CTL) |
| Bloqueio de apps | Airplane Mode ✈️ | Quiet Carriage / Vagão Silencioso 🚃 |
| Histórico | Focus History (voos) | Logbook de viagens |

### 1.2 Objetivos do produto

- Tornar sessões de foco emocionalmente recompensadoras através de uma narrativa de viagem ferroviária.
- Gamificar a concentração: cada sessão completa = um trecho percorrido, uma estação alcançada, um ticket carimbado.
- Reduzir distrações com bloqueio de apps durante a viagem (modo Vagão Silencioso).
- Registrar o histórico de foco como um logbook de viagens — milhas/quilômetros acumulados, estações visitadas, rotas favoritas.
- Manter o padrão de polimento visual premium (estilo Apple/Notion) com modo escuro como base.

### 1.3 Público-alvo

- Estudantes e concurseiros que precisam de blocos longos de estudo focado.
- Profissionais de conhecimento (devs, designers, escritores) que trabalham por sprints de foco.
- Entusiastas de produtividade que gostam de gamificação e tracking.

---

## 2. Design System

O design system replica a linguagem visual do FocusFlight: fundo escuro profundo, tipografia geométrica de alto contraste com palavras-chave destacadas, botões pill (totalmente arredondados), grandes áreas de respiro e transições suaves entre telas. A diferença está na paleta de acento (vermelho/latão ferroviário em vez do amarelo de aviação) e nos ícones (trens, trilhos, estações).

### 2.1 Paleta de Cores

Núcleo escuro herdado do FocusFlight, com acento ferroviário. Use o vermelho-trilho como cor de marca primária (equivalente ao amber do FocusFlight) e o latão como secundária para detalhes de ticket.

| Token | Hex | Uso |
|---|---|---|
| `bg/primary` | `#000000` | Fundo principal (telas escuras) |
| `bg/elevated` | `#0F1729` | Cartões, superfícies elevadas |
| `brand/rail` | `#C0392B` | Acento de marca, estações ativas, CTA destaque |
| `brand/brass` | `#E0A458` | Detalhes de ticket, ícones secundários |
| `text/primary` | `#FFFFFF` | Títulos e texto principal (no escuro) |
| `text/secondary` | `#9CA3AF` | Subtítulos, legendas |
| `text/muted` | `#6B7280` | Texto desabilitado / hint |
| `surface/light` | `#F4F4F6` | Telas claras (ticket, scenario picker) |
| `ink` | `#1A1A2E` | Texto sobre superfícies claras |
| `success` | `#22C55E` | Status ARRIVED / ON (labels) |
| `rail/line` | `#FFFFFF` | Linha de trilho no mapa |

**Regra de contraste:** telas de narrativa/onboarding usam fundo preto com palavra-chave em cor (ex.: `distracted?` em azul-aço no original → no RailFocus, a palavra-chave de problema fica em vermelho-trilho). Telas funcionais (ticket, seleção) podem inverter para fundo claro.

### 2.2 Tipografia

| Estilo | Fonte | Tamanho/Peso | Uso |
|---|---|---|---|
| Display | SF Pro Rounded / Inter | 40–52 / Bold | Palavras-chave de onboarding |
| Title | SF Pro Display | 28–34 / Bold | Títulos de tela |
| Body | SF Pro Text / Inter | 17–20 / Regular | Texto descritivo |
| Mono (ticket) | SF Mono / JetBrains | 14–20 / Medium | Códigos de estação, dados do ticket |
| Caption | SF Pro Text | 12–14 / Regular | Labels, rodapés |

**Princípio do FocusFlight a manter:** títulos enormes com hierarquia em duas camadas — linha de contexto menor e em cinza (`There's a solution:`) seguida da palavra-chave gigante e em destaque (`Hyperfocus.`). No RailFocus: `A solução é:` + `Trilho único.` / `Single track.`

### 2.3 Componentes-base

#### Botão Pill (primário)
- Totalmente arredondado (border-radius = altura/2), largura quase total, ~64pt de altura.
- Estados: claro sobre escuro (`Hi!`, `Start Journey`) e escuro sobre claro (`Continue`).
- Estado de loading: spinner centralizado, fundo cinza (visto no Airplane Mode → aqui "Vagão Silencioso").

#### Botão de texto (terciário)
- `Skip` em peso médio, sem fundo, abaixo do CTA principal.

#### Indicador de progresso (stepper)
- Barras horizontais no topo (4 segmentos), preenchidas conforme avança o onboarding — idêntico ao FocusFlight.

#### Train Ticket Card (equivalente ao Boarding Pass)
- Cartão claro com cantos arredondados e dois "recortes" laterais (notches) imitando bilhete físico.
- Topo: ORIGEM → 🚆 → DESTINO (códigos grandes de estação) + duração no meio.
- Meio: Assento, Distância (km), Embarque (Now), Data.
- Base: código de barras / QR fictício. Status badge `ARRIVED` em verde.
- Empilhamento: ticket atual na frente, tickets anteriores levemente atrás e rotacionados.

#### Scenario Chips (seleção de cenário)
- Pills coloridas com ícone + label, dispostas em mosaico orgânico; algumas na vertical.
- Cores pastéis suaves (verde, lilás, azul, bege) sobre fundo claro.

#### Map Style Selector
- Grid 2×2 de miniaturas: Monochrome, Terra, Standard, Satellite + toggle `Labels ON/OFF`.
- Item selecionado recebe borda branca de destaque.

### 2.4 Ícones & Ilustrações

**Substituições temáticas:** ✈️ avião → 🚆 trem; pista/rota aérea → trilhos; aeroporto → estação; boarding pass → ticket; globo 3D → globo com malha ferroviária ou mapa de linhas estilo metrô.

- Ícone de marca: vagão/locomotiva minimalista dentro de um quadrado arredondado (como o logo FocusFlight).
- Ícones de feature: "Train Ticket" (ícone de bilhete), "Travel Logbook" (relógio/registro).

### 2.5 Animações & Transições

- Telas de narrativa fazem scroll/fade: o texto anterior desbota ao fundo enquanto o novo entra (visível nas telas 2→4 do FocusFlight).
- Glow animado na marca (`RailFocus` com leve brilho), como o efeito arco-íris em `FocusFlight`.
- Linha do trilho desenhada progressivamente entre as duas estações no mapa (em vez da linha de voo LHR→CDG).
- Globo 3D girando suavemente nas telas de mapa/boas-vindas.
- Trem percorrendo o trilho em tempo real durante a sessão ativa (progresso = posição na linha).

---

## 3. Fluxo de Onboarding (tela a tela)

Mapeamento direto das 13 telas do FocusFlight, reescritas para o tema ferroviário. A estrutura, os tipos de tela e a ordem permanecem idênticos para preservar a qualidade do fluxo original.

### 3.1 Sequência narrativa (telas 1–6)

| # | Tipo de tela | Conteúdo (RailFocus) | CTA |
|---|---|---|---|
| 1 | Boas-vindas (preta) | "Bem-vindo a bordo! 👋 Sua jornada para o foco profundo parte daqui." | `Olá!` |
| 2 | Pergunta-problema | "Você se sente sempre... **distraído?**" (palavra-chave em vermelho-trilho) | `Sim, me sinto.` |
| 3 | Solução | "Existe uma solução: **Trilho único.**" — manter o trem nos trilhos é bloquear distrações e seguir engajado. | `Qual a chave do trilho único?` |
| 4 | Revelação da marca | "Por isso criamos **RailFocus**" (com glow animado) | `Vamos começar!` |
| 5 | Mapa + proposta | Mapa com trilho entre duas estações (ex.: LUZ → CTL). "RailFocus transforma cada sessão numa viagem de trem rumo ao **foco profundo**." | `Continuar` |
| 6 | Features (ticket) | Train Ticket Card + "Train Ticket: toda viagem é uma jornada de foco." / "Travel Logbook: cada viagem marca um marco." | `Continuar` |

### 3.2 Configuração (telas 7–13)

| # | Tipo de tela | Conteúdo (RailFocus) | CTA |
|---|---|---|---|
| 7 | Escolha de cenário | "Escolha seu cenário de foco 🎫" — chips: Ler, Pesquisar, Exercício, Podcast, Design, Trabalho, Meditar, Codar, Viajar, Aprender, Escrever, Cozinhar, Explorar, Foco. | `Continuar` |
| 8 | Bloqueio de apps | "Vagão Silencioso 🚃 — reduz distrações gerenciando o tempo de tela." (ícones de apps girando ao redor de cadeado/ampulheta) | `Continuar` / `Pular` |
| 9 | Bloqueio (loading) | Mesmo da 8, com botão em estado de loading (spinner) | `Pular` |
| 10–12 | Estilo de mapa | "Escolha o estilo do mapa 🗺️" — Monochrome, Terra, Standard, Satellite + Labels ON/OFF. Globo 3D ao fundo. | `Continuar` |
| 13 | Boas-vindas final | Globo 3D + "Bem-vindo ao RailFocus" | `Iniciar Jornada` |

> **Nota de UX:** o stepper de 4 segmentos no topo aparece a partir da tela 7 (configuração), exatamente como no FocusFlight.

---

## 4. Telas Principais do App (pós-onboarding)

O FocusFlight não mostrou as telas internas nos screenshots, então estas são especificadas para completar o produto, mantendo a metáfora ferroviária e a linguagem visual definida.

### 4.1 Home / Estação
- Globo 3D ou mapa de linhas (estilo escolhido no onboarding) como plano de fundo.
- Card central "Próxima viagem": cenário selecionado, duração-alvo, estação de origem e destino sugeridos.
- Botão grande "Embarcar" (inicia a sessão de foco).
- Resumo rápido: km percorridos hoje, sequência (streak) de dias, viagens da semana.

### 4.2 Sessão Ativa / Em Viagem
- Mapa com o trem percorrendo o trilho da origem ao destino; o progresso reflete o tempo decorrido.
- Timer central grande (contagem regressiva ou progressiva).
- Indicador de "Vagão Silencioso" ativo (apps bloqueados).
- Ações: pausar (parada de emergência), encerrar viagem antecipadamente (desce na próxima estação).
- Eventos de marco: ao cruzar paradas intermediárias, micro-animação/feedback (ex.: "Parada 1 de 3 alcançada").

### 4.3 Chegada / Resumo da Viagem
- Animação de chegada à estação + badge `ARRIVED`.
- Train Ticket Card gerado para a sessão (origem→destino, duração, distância, data, assento aleatório).
- Opção de compartilhar o ticket (imagem).

### 4.4 Logbook / Histórico
- Lista/pilha de tickets de viagens passadas (cards empilhados como no FocusFlight).
- Estatísticas: total de km, total de horas focadas, estações visitadas, rota mais frequente, mapa de calor por dia.
- Filtros por cenário (estudar, codar, escrever...).

### 4.5 Perfil / Configurações
- Editar cenários, estilo de mapa, lista de apps bloqueados, durações padrão.
- Conta, assinatura (paywall premium), notificações, idioma (pt-BR / en).

---

## 5. Escopo de Funcionalidades

### 5.1 MVP (v1.0)
1. Onboarding completo (13 telas) com tema ferroviário.
2. Seleção de cenário de foco e estilo de mapa.
3. Sessão de foco com timer + animação do trem no trilho.
4. Bloqueio de apps (Vagão Silencioso) via Screen Time API (iOS).
5. Geração de Train Ticket ao concluir a sessão.
6. Logbook com histórico e estatísticas básicas (km, horas, streak).
7. Modo escuro como padrão; persistência local dos dados.

### 5.2 Pós-MVP / Futuro
- Rotas reais entre estações famosas e desbloqueio progressivo de "linhas" do mundo.
- Modo colaborativo: "viajar junto" (sessões compartilhadas).
- Sons ambientes de trem (white noise) durante a viagem.
- Widgets de tela inicial e Live Activities (trem em andamento na Dynamic Island).
- Conquistas/achievements e colecionáveis (selos de estação).
- Sincronização em nuvem e versão Android/Web.

### 5.3 Não-objetivos (v1.0)
- Integração com calendário/tarefas.
- Social feed público.
- Dados ferroviários reais em tempo real (a malha é estética, não funcional).

---

## 6. Stack Técnica Sugerida

| Camada | Tecnologia |
|---|---|
| App (iOS nativo) | Swift + SwiftUI; MapKit ou Mapbox para globo/mapa de trilhos; SpriteKit/Canvas para animação do trem |
| Bloqueio de apps | FamilyControls + ManagedSettings + DeviceActivity (Screen Time API) |
| Persistência | SwiftData ou Core Data (local); CloudKit para sync futuro |
| Live Activities | ActivityKit (trem em progresso na Dynamic Island) |
| Backend (opcional) | Supabase (auth, sync, assinatura) |
| Pagamentos | StoreKit 2 (assinatura premium / one-time) |

> **Observação:** como alternativa multiplataforma rápida, é viável React Native + Expo, porém o bloqueio de apps de qualidade e as Live Activities pedem o caminho nativo SwiftUI — recomendado para fidelidade ao padrão FocusFlight.

### 6.1 Glossário de termos (de avião → trem)

- Flight → Trip / Viagem
- Boarding Pass → Train Ticket / Bilhete
- Airport (IATA) → Station (sigla de 3 letras)
- Takeoff/Landing → Departure/Arrival (Partida/Chegada)
- Airplane Mode → Quiet Carriage / Vagão Silencioso
- Flight path → Rail line / Trilho
- Focus History → Travel Logbook / Diário de bordo

---

### Próximo passo sugerido

Com este documento, posso gerar na sequência: **(1)** prompts prontos para Lovable/Claude Code montando o onboarding em SwiftUI ou React, tela a tela; e **(2)** os tokens de design em formato de código (Swift `Color` extension ou Tailwind config). É só pedir qual você quer primeiro.