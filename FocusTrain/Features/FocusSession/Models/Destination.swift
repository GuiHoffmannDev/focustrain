import SwiftUI

/// One stop on the duration ladder. Picking a destination sets both the route's
/// destination and the focus duration. `nominalKm` is a *stylized* distance that
/// grows with `minutes` (shown on cards/radar) — not a real great-circle value.
struct Destination: Identifiable, Hashable {
    let station: Station
    let minutes: Int
    let nominalKm: Int
    /// Curated angle on the radar ring (degrees, 0 = right, clockwise). Not a geographic bearing.
    let radarDegrees: Double

    var id: String { station.code }
    var code: String { station.code }
    var city: String { station.city }
}

extension Destination {
    /// Fixed 9-stop ladder (15–90 min). All codes exist in `StationPool`.
    static let ladder: [Destination] = {
        let rows: [(code: String, minutes: Int, km: Int)] = [
            ("LIS", 15,  250), ("MAD", 20,  400), ("PAR", 25,  600),
            ("ROM", 30,  850), ("IST", 40, 1300), ("DXB", 50, 2000),
            ("DEL", 60, 3000), ("BKK", 75, 4500), ("TYO", 90, 6500),
        ]
        let n = rows.count
        let start = 130.0, sweep = 280.0   // spread across a 280° arc, gap at bottom
        return rows.enumerated().map { idx, r in
            guard let station = StationPool.station(forCode: r.code) else {
                fatalError("Destination ladder references unknown station code \(r.code)")
            }
            let deg = start + sweep * Double(idx) / Double(n - 1)
            return Destination(station: station, minutes: r.minutes, nominalKm: r.km, radarDegrees: deg)
        }
    }()
}

#if DEBUG
#Preview("Destination ladder self-check") {
    let l = Destination.ladder
    let countOK   = l.count == 9
    let codesOK   = l.allSatisfy { StationPool.station(forCode: $0.code) != nil }
    let minutesOK = zip(l, l.dropFirst()).allSatisfy { $0.minutes < $1.minutes }
    let kmOK      = zip(l, l.dropFirst()).allSatisfy { $0.nominalKm < $1.nominalKm }
    let pass = countOK && codesOK && minutesOK && kmOK
    return VStack(alignment: .leading, spacing: 6) {
        Text(pass ? "PASS ✓" : "FAIL ✗").font(.title.bold())
            .foregroundStyle(pass ? .green : .red)
        Text("count=\(l.count) codes=\(codesOK) minutesAsc=\(minutesOK) kmAsc=\(kmOK)")
            .font(.caption.monospaced())
        ForEach(l) { d in Text("\(d.minutes)m · \(d.code) \(d.city) · ~\(d.nominalKm)km · \(Int(d.radarDegrees))°").font(.caption2.monospaced()) }
    }.padding()
}
#endif
