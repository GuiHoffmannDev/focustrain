import Foundation

/// Absolute path to the prebuilt database in the repo's Resources folder.
/// Resolved from this file's location so it works from any checkout:
/// `<repo>/Tests/CitiesHarness/Tests/CitiesKitTests/<file>.swift` → repo root.
func citiesSQLitePath(file: String = #filePath) -> String {
    var url = URL(fileURLWithPath: file)
    for _ in 0..<5 { url.deleteLastPathComponent() }
    return url.appendingPathComponent("FocusTrain/Resources/cities.sqlite").path
}

import CoreLocation

/// São Paulo city centre — the spec's reference origin.
let saoPaulo = CLLocationCoordinate2D(latitude: -23.5505, longitude: -46.6333)
