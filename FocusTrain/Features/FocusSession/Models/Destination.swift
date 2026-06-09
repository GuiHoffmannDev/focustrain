import CoreLocation
import SwiftUI

/// One stop on the duration ladder. Picking a destination sets both the route's
/// destination and the focus duration. `nominalKm` is the great-circle distance
/// from origin (km), shown on cards/radar. `radarDegrees` is the bearing from
/// origin used to position the pin on the radar ring (0 = north, clockwise).
struct Destination: Identifiable, Hashable {
    let station: Station
    let minutes: Int
    let nominalKm: Int
    let radarDegrees: Double

    var id: String { station.code }
    var code: String { station.code }
    var city: String { station.city }
}

extension Destination {
    /// Compact duration label: minutes only under an hour ("45m"), hours +
    /// minutes at or above ("1h 10m", "2h").
    var durationLabel: String { Self.durationLabel(minutes: minutes) }

    static func durationLabel(minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        if h == 0 { return "\(m)m" }
        if m == 0 { return "\(h)h" }
        return "\(h)h \(m)m"
    }

    /// 12-entry duration ladder, in minutes.
    static let durationLadder: [Int] = [
        15, 20, 25, 30, 40, 50, 60, 75, 90, 105, 120, 150,
    ]

    /// Fictional regional-rail cruise speed (km/h). One knob that controls how
    /// dense or sparse the ladder feels: distance bucket per slot is
    /// `(minutes / 60) * fictionalSpeedKmh`.
    static let fictionalSpeedKmh: Double = 80

    /// Builds the destination ladder by bucketing nearby `candidates` (from
    /// `CityDatabase.nearby`) against a per-slot target distance. For each
    /// duration in `durationLadder`:
    ///
    /// 1. `target = (minutes / 60) * fictionalSpeedKmh`
    /// 2. Tries tolerance bands ±25%, ±50%, ±100% in order.
    /// 3. Within the band, picks the unused city closest to `target`.
    /// 4. If no candidate fits even at ±100%, the slot is omitted — the ladder
    ///    may have fewer than 12 entries (UI degrades gracefully).
    static func makeLadder(origin: Station, candidates: [City]) -> [Destination] {
        guard !candidates.isEmpty else { return [] }

        let originCoord = origin.coordinate
        let scored: [(city: City, distanceKm: Double)] = candidates.map { city in
            (city, GreatCircle.distanceKm(originCoord, city.coordinate))
        }

        var used: Set<Int> = []
        var result: [Destination] = []
        result.reserveCapacity(durationLadder.count)

        for minutes in durationLadder {
            let target = Double(minutes) / 60.0 * fictionalSpeedKmh
            var picked: (city: City, distanceKm: Double)?
            for tolerance in [0.25, 0.5, 1.0] {
                let low = target * (1 - tolerance)
                let high = target * (1 + tolerance)
                var bestDelta = Double.greatestFiniteMagnitude
                for candidate in scored {
                    if used.contains(candidate.city.geonameId) { continue }
                    if candidate.distanceKm < low || candidate.distanceKm > high { continue }
                    let delta = abs(candidate.distanceKm - target)
                    if delta < bestDelta {
                        bestDelta = delta
                        picked = candidate
                    }
                }
                if picked != nil { break }
            }
            guard let (city, dist) = picked else { continue }
            used.insert(city.geonameId)
            let cityCoord = city.coordinate
            let bearing = GreatCircle.bearing(from: originCoord, to: cityCoord)
            let station = Station.make(city: city.name, coordinate: cityCoord)
            result.append(
                Destination(
                    station: station,
                    minutes: minutes,
                    nominalKm: max(1, Int(dist.rounded())),
                    radarDegrees: bearing
                )
            )
        }
        return result
    }
}
