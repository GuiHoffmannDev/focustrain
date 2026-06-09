import CoreLocation
import Testing
@testable import CitiesKit

@Suite struct CityDatabaseTests {
    let db = CityDatabase(path: citiesSQLitePath())

    @Test func nearbyReturnsCitiesWithinRadiusNearestFirst() async {
        let hits = await db.nearby(center: saoPaulo, radiusKm: 400, limit: 1500)

        #expect(hits.count > 100) // SP region is dense
        #expect(hits.allSatisfy { GreatCircle.distanceKm(saoPaulo, $0.coordinate) <= 400 })

        let dists = hits.map { GreatCircle.distanceKm(saoPaulo, $0.coordinate) }
        #expect(dists == dists.sorted()) // nearest first
        #expect(hits.contains { $0.asciiName.lowercased().hasPrefix("sao paulo") })
    }

    @Test func nearbyRespectsLimit() async {
        let hits = await db.nearby(center: saoPaulo, radiusKm: 400, limit: 10)
        #expect(hits.count == 10)
    }

    @Test func nearbySpreadCanFillTheLadder() async {
        // The 150-minute ladder slot targets ~200 km; the 400 km query must
        // return candidates spread far enough to fill the top rungs.
        let hits = await db.nearby(center: saoPaulo, radiusKm: 400, limit: 1500)
        let maxKm = hits.map { GreatCircle.distanceKm(saoPaulo, $0.coordinate) }.max() ?? 0
        #expect(maxKm > 150)
    }

    @Test func searchFindsSaoPauloDespiteDiacritics() async {
        let hits = await db.search(query: "São", limit: 20)
        #expect(hits.contains { $0.asciiName.lowercased().hasPrefix("sao paulo") })
    }

    @Test func searchRanksHeaviestFirst() async {
        let hits = await db.search(query: "Lond", limit: 20)
        #expect(!hits.isEmpty)
        let pops = hits.map(\.population)
        #expect(pops == pops.sorted(by: >))
    }

    @Test func searchIgnoresShortQueries() async {
        let hits = await db.search(query: "S", limit: 20)
        #expect(hits.isEmpty)
    }

    @Test func nearestCityAtSaoPauloCentreIsAdjacent() async {
        // GeoNames lists SP's central districts (Sé, Bela Vista…) as their own
        // cities5000 entries, so the nearest to the centre is one of those. The
        // contract is "the closest city" — at a dense centre it's on top of us.
        let city = await db.nearestCity(to: saoPaulo)
        #expect(city != nil)
        if let city {
            #expect(GreatCircle.distanceKm(saoPaulo, city.coordinate) < 5)
        }
    }

    @Test func nearestCityOffshoreResolvesViaGrowingRings() async {
        // Just off the São Paulo coast: the inner rings are empty water, so this
        // exercises the outward ring growth before it hits a coastal city.
        let offshore = CLLocationCoordinate2D(latitude: -25.5, longitude: -46.0)
        let city = await db.nearestCity(to: offshore)
        #expect(city != nil)
        if let city {
            #expect(GreatCircle.distanceKm(offshore, city.coordinate) <= 800)
        }
    }
}
