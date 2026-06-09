# Prompt de kickoff — cole numa nova conversa do Claude Code

> Copie tudo abaixo da linha. Comece a mensagem com `ultrathink`.

---

ultrathink

Você vai implementar uma re-arquitetura já desenhada e aprovada no app **FocusTrain** (iOS,
SwiftUI + SwiftData; timer de foco com tema de trem). O design foi fechado num brainstorming
anterior — **não re-brainstormar, não re-litigar as decisões.** Implemente o que está no spec.

**Leia primeiro, na íntegra:**
`docs/superpowers/specs/2026-06-07-cities-sqlite-and-clean-home-design.md`

## O que vamos resolver
1. **Home poluída:** hoje a Home monta a ladder de destinos e desenha pontos + linhas de cada
   estação. Quero a Home **totalmente limpa** (só globo centrado na cidade + pin pulsante + textos).
2. **App pesado / tela branca no aparelho físico:** hoje o app carrega ~69 mil cidades na RAM no
   launch (`CityCatalog`) e varre o continente inteiro com `CLLocation.distance` pra montar a
   ladder. Vamos trocar por um **SQLite com índice espacial R-tree**, consultado por raio, sob
   demanda.

## Decisões já tomadas (não mudar sem me perguntar)
- **Armazenamento:** `cities.sqlite` pré-construído com **R-tree**, consultado sob demanda
  (nada de carregar o dataset na RAM).
- **Acesso:** **SQLite3 puro** (`import SQLite3`, já vem no iOS). **Zero dependência externa** — não
  adicione pacote SPM.
- **Home:** globo **totalmente limpo** (remove pontos das estações, linhas de preview E linhas de
  histórico).
- **Dataset:** mantém população ≥ 5000.
- **Remover `Continent`** (filtro por continente vira redundante com a query por raio).

## Constraints do projeto (importante)
- **Não editar `project.pbxproj` na mão.** O projeto usa synced file groups (novos `.swift` entram
  no target sozinhos). Pro `cities.sqlite`: gere o arquivo em `FocusTrain/Resources/` e
  **confirme que ele foi pro "Copy Bundle Resources"** do target — se não for, `nearby` volta vazio
  no device e o picker fica sem destinos.
- **Não redesenhe o picker/radar nem a sessão ativa.** A aparência e o feel do picker devem ficar
  **idênticos** — só troca a fonte de dados (catálogo em memória → `CityDatabase`).
- Brand accent do app é branco (`FT.Palette.brandRail` = #FFFFFF).

## Como trabalhar
- **Branch primeiro:** estamos em `main` com bastante coisa não-commitada. Crie um branch antes de
  começar; **não commite em `main` direto.**
- Siga a **Sequência de implementação** do spec (Fases 0→5). Use **TDD** onde fizer sentido
  (`CityDatabase` e `makeLadder` têm testes descritos no spec).
- Pode usar a skill `superpowers:executing-plans` / `superpowers:test-driven-development`.

## Verificação (obrigatória antes de dizer "pronto")
- Testes das Fases 1-2 passando.
- **Simulador:** Home limpa (sem pontos/linhas); picker mostra o radar igual a antes; iniciar uma
  sessão funciona ponta a ponta.
- **Aparelho físico:** a **tela branca sumiu**. Se persistir, **pegue o log do console** (Xcode →
  Devices and Simulators → Console) pra achar bug não-relacionado, e me reporte com o output.
- Confirme **zero parse de cidades no launch** (o log antigo `[CityCatalog] loaded ... cities` não
  deve mais aparecer) e logue o tempo da query `nearby` (esperado <5ms).

Comece lendo o spec e me devolvendo um plano curto das Fases antes de escrever código.
