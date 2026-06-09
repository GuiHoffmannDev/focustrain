import CoreLocation
import Testing
@testable import CitiesKit

@Suite struct GreatCircleTests {
    @Test func distanceSaoPauloToRioIsAboutThreeFiftySeven() {
        let rio = CLLocationCoordinate2D(latitude: -22.9068, longitude: -43.1729)
        let km = GreatCircle.distanceKm(saoPaulo, rio)
        // Great-circle SP→Rio ≈ 357 km.
        #expect(abs(km - 357) < 15)
    }

    @Test func distanceIsZeroForIdenticalPoints() {
        let p = CLLocationCoordinate2D(latitude: 10, longitude: 20)
        #expect(GreatCircle.distanceKm(p, p) == 0)
    }
}
