# Cidades em SQLite + Home limpa — Design

- **Data:** 2026-06-07
- **Status:** Aprovado (brainstorming concluído), pronto pra implementação
- **Branch alvo:** a definir na nova conversa (NÃO implementar em `main` direto — branch primeiro)

---

## Contexto / Problema

Dois problemas, ambos com raiz na camada de dados de cidades.

### Problema 1 — Pontos poluindo a Home
`HomeView` monta a ladder de destinos no `onAppear` (`HomeView.swift:142` → `reloadNearby()`)
e joga em `nearbyStations`. O `GlobeHomeView` desenha **um ponto + uma linha de preview por
estação** (`GlobeHomeView.swift:102-115`), além das linhas de viagens passadas. O usuário quer
a Home **totalmente limpa** (só globo + pin pulsante + textos).

O picker de destino (a tela do "radar", referência visual do usuário) monta a **própria** ladder
de forma independente em `DurationPickerModel.scheduleLoad()` (`DurationPickerModel.swift:131`).
Logo, dá pra limpar a Home **sem afetar** o picker.

### Problema 2 — App pesado / tela branca no aparelho físico
- No launch, `CityCatalog.bootstrap()` descompacta `cities5000.tsv.gz` (1,8 MB) e faz parse de
  **~69 mil cidades** pra RAM, duplicando num dicionário por continente, e segura tudo o app
  inteiro (`CityCatalog.swift:21-82`).
- `Destination.makeLadder` roda `CLLocation.distance` sobre **o continente inteiro** (15-25 mil
  cidades), criando dezenas de milhares de `CLLocation`, **toda vez que a origem muda** — e isso
  roda na Home E no picker (`Destination.swift:49-52`).
- **Insight central:** todo destino da ladder está a no máximo ~200 km da origem
  (150 min × 80 km/h ÷ 60). Com a banda de tolerância máxima (±100%), o candidato mais distante
  fica em ~400 km. Varremos um continente pra escolher 12 cidades num raio de 400 km — exagero de
  ~1000×.

**Tela branca no device:** hipótese mais forte = custo de memória/CPU dessa camada junto com o
MapKit sob as restrições do aparelho (o screenshot com pontos é do simulador; o branco é no device
físico). Não confirmado sem log do console. A re-arquitetura remove justamente o trabalho mais
pesado do launch e do fluxo principal — o suspeito nº 1 — então é a correção certa independente da
causa exata. **Pegar log do console do aparelho faz parte da verificação.**

---

## Decisões (já tomadas no brainstorming)

1. **Armazenamento:** `cities.sqlite` pré-construído com índice espacial **R-tree**, consultado
   sob demanda. Nada de carregar o dataset inteiro na RAM.
2. **Acesso:** **SQLite3 puro** (`import SQLite3`, já vem no iOS). Zero dependência externa,
   nada de adicionar pacote SPM. Wrapper fino próprio, isolado num arquivo.
3. **Home:** **globo totalmente limpo** — remove pontos das estações, linhas de preview E linhas
   de histórico. Marcador visual = só o `PulsingPin` (overlay SwiftUI).
4. **Dataset:** mantém população ≥ 5000 (densidade total) — em disco é barato.
5. **`Continent`:** **remover.** Com a query por raio, o filtro "trem não cruza oceano" vira
   redundante. Simplifica `HomeCityStore.resolveOrigin` pra devolver só `Station`.

### Constraints do projeto (de memória)
- **Synced file groups:** novos `.swift` entram no target automaticamente. **NÃO editar
  `project.pbxproj` na mão.** O `cities.sqlite` deve entrar no bundle pelo synced group —
  **verificar** que ele foi pro "Copy Bundle Resources" (gotcha clássico de "some no device").
- **Preservar composições existentes:** o picker/radar **não muda de aparência nem de feel** —
  só troca a fonte de dados (catálogo em memória → `CityDatabase`). Não redesenhar.

---

## Arquitetura

### Fluxo novo
```
launch ──> (nada de cidades carregado)

picker abre ──> CityDatabase.nearby(origin, radiusKm: 400, limit: 1500)
                  └─ bounding-box ─> query R-tree ─> refine haversine ─> [City] (centenas)
                ──> Destination.makeLadder(origin, candidates) ─> [Destination] (~12)

Home abre ───> só mostra o globo centrado na cidade (sem ladder, sem pontos)
```

### 1. Build-time — `scripts/build-cities-bundle.py`
Estender o script pra emitir `FocusTrain/Resources/cities.sqlite` (Python tem `sqlite3` na stdlib):

```sql
CREATE TABLE city (
  geonameId  INTEGER PRIMARY KEY,
  name       TEXT NOT NULL,
  asciiName  TEXT NOT NULL,
  countryCode TEXT NOT NULL,
  lat        REAL NOT NULL,
  lon        REAL NOT NULL,
  population INTEGER NOT NULL
);
CREATE INDEX idx_city_asciiname ON city(asciiName COLLATE NOCASE);

CREATE VIRTUAL TABLE city_rtree USING rtree(id, minLat, maxLat, minLon, maxLon);
INSERT INTO city_rtree(id, minLat, maxLat, minLon, maxLon)
  SELECT geonameId, lat, lat, lon, lon FROM city;   -- ponto: min == max
```
Finalizar com `ANALYZE;` e `VACUUM;`. **Parar de gerar** a tabela `Continent.byCountryCode`.
Conferir contagem (`SELECT count(*) FROM city;` ~69k) e tamanho do arquivo.

> R-tree guarda min/max como float 32-bit (~1m de precisão nessas magnitudes) — ok, porque é só o
> filtro grosso. A distância final é refinada com o `lat/lon` REAL (64-bit) da tabela `city`.

### 2. Runtime — `CityDatabase` (substitui `CityCatalog`)
`actor` (serializa o acesso ao handle único do SQLite). Abre o `.sqlite` **read-only, lazy**
(na 1ª query, não no launch): `sqlite3_open_v2(..., SQLITE_OPEN_READONLY, nil)`.

API:
```swift
actor CityDatabase {
    static let shared = CityDatabase()
    func nearby(center: CLLocationCoordinate2D, radiusKm: Double, limit: Int) -> [City]
    func search(query: String, limit: Int) -> [City]
    func nearestCity(to coordinate: CLLocationCoordinate2D) -> City?
}
```

**`nearby`** — bounding-box → R-tree → refine:
```
latDelta = radiusKm / 111.0
lonDelta = radiusKm / (111.0 * max(cos(centerLat·π/180), 0.01))   // clamp p/ polos
box = [centerLat ± latDelta, centerLon ± lonDelta]
```
```sql
SELECT c.geonameId, c.name, c.asciiName, c.countryCode, c.lat, c.lon, c.population
FROM city_rtree r JOIN city c ON c.geonameId = r.id
WHERE r.maxLat >= :minLat AND r.minLat <= :maxLat
  AND r.maxLon >= :minLon AND r.minLon <= :maxLon;
```
Depois: refina por **haversine ≤ radiusKm**, ordena por distância, corta em `limit`.
Helper `haversineKm(_:_:)` sem alocação (substitui `CLLocation.distance`).

**`search`** — `LIKE` indexado (prefixo usa o índice):
```sql
SELECT ... FROM city WHERE asciiName LIKE :q COLLATE NOCASE
ORDER BY population DESC LIMIT :limit;   -- :q = query + '%'
```

**`nearestCity`** — bbox crescente (50→100→200→400→800 km) até achar; exato entre os achados.
(Substitui o brute-force O(N) do `CityCatalog.nearestCity`.)

> Cada query: prepara statement, faz bind, `sqlite3_step` em loop, `sqlite3_finalize`. Tratar
> erros. Reaproveitar statements preparados quando fizer sentido.

### 3. Ladder — `Destination.makeLadder`
- **Nova assinatura:** recebe candidatos locais (do `nearby`), sem `catalog` continental e sem
  `continent`:
  ```swift
  static func makeLadder(origin: Station, candidates: [City]) -> [Destination]
  ```
- Trocar `CLLocation.distance` por `haversineKm`. Mesmo algoritmo de bucketing (targets, tolerância
  ±25/50/100%, "unused city closest to target"), mesmo resultado visual.
- **`DurationPickerModel.scheduleLoad`**: chamar
  `CityDatabase.shared.nearby(center: origin.coordinate, radiusKm: 400, limit: 1500)` e passar pro
  `makeLadder`. Remove o uso de `continent`.

### 4. Home limpa
- **`GlobeHomeView`**: vira só o mapa centrado na cidade. Remove params `nearbyStations` e
  `routes`; remove overlays, annotations e o Coordinator de stations/histórico. Fica: configura o
  `MKMapView`, aplica a câmera (região regional ao redor do `center`), aplica style/labels.
- **`HomeView`**: remove `nearbyStations`, `reloadNearby()`, `loaderTask` e os `onChange`
  (`resolver.cityName`/`countryCode`/`manualCity`) que disparavam o reload da ladder. O
  `PulsingPin` continua como marcador. Mantém greeting, city name, CTAs, banner de localização.

### 5. Remoções / cleanup
- Apagar: `cities5000.tsv.gz`, `Data+Gunzip.swift`, `CityCatalog.swift`.
- Apagar `Continent.swift`; `HomeCityStore.resolveOrigin` passa a devolver só `Station`. Ajustar
  consumidores (`HomeView.resolvedOrigin`, `DurationPickerModel`). **Grep** antes pra garantir que
  nenhum outro lugar usa `Continent`.
- `FocusTrainApp.init` não chama mais `CityCatalog.bootstrap()` (sem warm-up no launch; a abertura
  é lazy na 1ª query).

---

## Sequência de implementação (TDD onde fizer sentido)

**Fase 0 — Dados (build-time)**
1. Estender `build-cities-bundle.py` pra gerar `cities.sqlite` (schema acima + R-tree + índice).
   Parar de gerar a tabela `Continent`.
2. Rodar o script, gerar o `.sqlite`, conferir `count(*)` e tamanho.
3. Garantir que `cities.sqlite` entra no bundle (synced group) e **confirmar no Copy Bundle
   Resources**.

**Fase 1 — `CityDatabase`**
4. (teste) abrir o `.sqlite`, `nearby(São Paulo, 400km)` retorna candidatos plausíveis e a ladder
   enche ~12 slots; `search("São")` acha São Paulo; `nearestCity` perto de SP volta SP.
5. Implementar `CityDatabase` (`import SQLite3`): open lazy read-only, `nearby`, `search`,
   `nearestCity`, helper haversine.
6. Verde.

**Fase 2 — Ladder**
7. (teste) `makeLadder(origin, candidates)` com conjunto pequeno → slots/distâncias corretos.
8. Mudar assinatura de `makeLadder` (sem `catalog` continental, sem `continent`); haversine.
9. `DurationPickerModel.scheduleLoad` → `CityDatabase.nearby` + `makeLadder`. Remove `continent`.
10. Verde. Conferir que o **picker continua idêntico** visualmente.

**Fase 3 — Home limpa**
11. Simplificar `GlobeHomeView` (sem stations/routes/annotations).
12. Limpar `HomeView`.
13. Build + Home limpa no simulador.

**Fase 4 — Remoções + Continent**
14. Remover `cities5000.tsv.gz`, `Data+Gunzip.swift`, `CityCatalog.swift`.
15. Remover `Continent`; `resolveOrigin` → `Station`; ajustar consumidores; grep de segurança.
16. `FocusTrainApp.init` sem `bootstrap()`.

**Fase 5 — Verificação** (ver abaixo)

---

## Verificação

- **Testes** das Fases 1-2 passando.
- **Simulador:** Home totalmente limpa (sem pontos/linhas); picker mostra o radar igual a antes;
  iniciar uma sessão funciona ponta a ponta.
- **Aparelho físico:** instalar e confirmar que a **tela branca sumiu**. Se persistir, **pegar log
  do console** (Xcode → Devices → Console / `Console.app`) pra achar bug não-relacionado.
- **`cities.sqlite` no bundle:** confirmar que o arquivo foi pro app (senão `nearby` volta vazio e
  o picker fica sem destinos — sinal de resource fora do target).
- **Performance:** logar o tempo de `nearby` (esperado <5ms) e confirmar **zero parse de cidades
  no launch** (sem o log antigo `[CityCatalog] loaded ... cities`).

---

## Edge cases / riscos
- **Antimeridiano (lon ±180) e polos:** a bbox simples falha perto de ±180° e o `cos(lat)` → 0 nos
  polos (já tem clamp). Pouquíssimas cidades ≥5000 lá; aceitar a borda ou dividir a box. Baixa
  prioridade.
- **Origem em região remota / oceano:** poucos/nenhum candidato no raio → ladder degrada pra menos
  de 12 slots (UI já trata). `nearestCity` cobre a resolução de origem.
- **R-tree habilitado:** o SQLite do iOS vem com `SQLITE_ENABLE_RTREE` — padrão. Confirmar na 1ª
  query (erro de "no such module: rtree" indicaria o contrário).
- **Densidade na Europa:** dentro de 400km pode ter milhares de cidades; `limit` de ~1500 + corte
  por haversine mantêm o `makeLadder` barato (12 × ~milhares de haversines sem alocação).

## Fora de escopo
- Redesenhar o picker/radar ou a sessão ativa.
- Mudar o algoritmo da ladder (targets, velocidade fictícia, tolerâncias) — só a fonte de dados.
- Busca fuzzy/FTS avançada (prefixo + contains já bastam pro "Cidade base").
