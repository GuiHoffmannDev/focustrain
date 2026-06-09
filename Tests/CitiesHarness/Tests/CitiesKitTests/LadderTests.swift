import CoreLocation
import Testing
@testable import CitiesKit

@Suite struct LadderTests {
    // Origin at (0,0); candidates placed due east so distance ≈ 111.19 km per
    // degree of longitude and the bearing from origin is ≈ 90°.
    let origin = Station(code: "ORG", city: "Origin", lat: 0, lon: 0)
    let kmPerDegree = 111.19492664455873

    func cityEast(km: Double, id: Int) -> City {
        City(
            geonameId: id, name: "City\(id)", asciiName: "City\(id)",
            countryCode: "XX", lat: 0, lon: km / kmPerDegree, population: 10_000
        )
    }

    /// The 12 per-slot target distances (minutes/60 × fictionalSpeedKmh).
    var targets: [Double] {
        Destination.durationLadder.map {
            Double($0) / 60 * Destination.fictionalSpeedKmh
        }
    }

    @Test func emptyCandidatesYieldEmptyLadder() {
        #expect(Destination.makeLadder(origin: origin, candidates: []).isEmpty)
    }

    @Test func oneCandidatePerTargetFillsAllTwelveSlots() {
        let candidates = targets.enumerated().map { i, t in cityEast(km: t, id: i + 1) }
        let ladder = Destination.makeLadder(origin: origin, candidates: candidates)

        #expect(ladder.count == Destination.durationLadder.count)
        #expect(ladder.map(\.minutes) == Destination.durationLadder)
        // Each slot picks its exact-distance candidate (delta ≈ 0).
        for dest in ladder {
            let target = Double(dest.minutes) / 60 * Destination.fictionalSpeedKmh
            #expect(abs(Double(dest.nominalKm) - target) <= 1)
        }
    }

    @Test func slotPicksCandidateClosestToTarget() {
        // 15-min slot, target 20 km — the first slot, so nothing steals its
        // candidates. Both 18 and 23 km sit inside the ±25% band [15,25]; 18 km
        // is closer to the 20 km target.
        let candidates = [cityEast(km: 23, id: 1), cityEast(km: 18, id: 2)]
        let ladder = Destination.makeLadder(origin: origin, candidates: candidates)
        let first = ladder.first { $0.minutes == 15 }
        #expect(first?.nominalKm == 18)
    }

    @Test func bearingForDueEastCandidateIsNinety() {
        let ladder = Destination.makeLadder(origin: origin, candidates: [cityEast(km: 80, id: 1)])
        #expect(ladder.contains { abs($0.radarDegrees - 90) < 0.5 })
    }

    @Test func eachCityIsUsedAtMostOnce() {
        let candidates = (1...40).map { cityEast(km: Double($0) * 8, id: $0) }
        let ladder = Destination.makeLadder(origin: origin, candidates: candidates)
        let cities = ladder.map(\.city)
        #expect(Set(cities).count == cities.count)
    }

    @Test func sparseCandidatesDegradeToFewerSlots() {
        // A single 200 km candidate fits only the slot whose ±100% band first
        // reaches it (60-min, target 80 → band [0,160]? no; 75-min target 100 →
        // [0,200] yes). Either way: far fewer than 12 slots, at least one.
        let ladder = Destination.makeLadder(origin: origin, candidates: [cityEast(km: 200, id: 1)])
        #expect(ladder.count >= 1)
        #expect(ladder.count < Destination.durationLadder.count)
    }
}
