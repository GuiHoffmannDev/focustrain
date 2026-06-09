import CoreLocation
import Foundation
import SQLite3

/// Read-only access to the prebuilt `cities.sqlite` (GeoNames cities5000,
/// CC-BY 4.0), queried by radius on demand via an R-tree spatial index. Nothing
/// is loaded into RAM at launch — the handle opens lazily on the first query.
///
/// An `actor` so the single SQLite handle is never touched concurrently.
actor CityDatabase {
    static let shared = CityDatabase()

    /// Explicit file path (used by tests). `nil` resolves `cities.sqlite` from
    /// the app bundle on first use.
    private let path: String?

    private var db: OpaquePointer?
    private var openAttempted = false

    init(path: String? = nil) {
        self.path = path
    }

    /// Cities within `radiusKm` of `center`, nearest first, capped at `limit`.
    /// Coarse R-tree bounding-box filter, then exact haversine refine.
    func nearby(center: CLLocationCoordinate2D, radiusKm: Double, limit: Int) -> [City] {
        guard limit > 0, let db = handle() else { return [] }
        let start = CFAbsoluteTimeGetCurrent()

        let latDelta = radiusKm / 111.0
        let lonDelta = radiusKm / (111.0 * max(cos(center.latitude * .pi / 180), 0.01))
        let minLat = center.latitude - latDelta
        let maxLat = center.latitude + latDelta
        let minLon = center.longitude - lonDelta
        let maxLon = center.longitude + lonDelta

        let sql = """
        SELECT c.geonameId, c.name, c.asciiName, c.countryCode, c.lat, c.lon, c.population
        FROM city_rtree r JOIN city c ON c.geonameId = r.id
        WHERE r.maxLat >= ? AND r.minLat <= ? AND r.maxLon >= ? AND r.minLon <= ?;
        """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            logError("nearby prepare")
            return []
        }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_double(stmt, 1, minLat)
        sqlite3_bind_double(stmt, 2, maxLat)
        sqlite3_bind_double(stmt, 3, minLon)
        sqlite3_bind_double(stmt, 4, maxLon)

        var hits: [(city: City, distanceKm: Double)] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            let city = readCity(stmt)
            let d = GreatCircle.distanceKm(center, city.coordinate)
            if d <= radiusKm { hits.append((city, d)) }
        }
        hits.sort { $0.distanceKm < $1.distanceKm }
        if hits.count > limit { hits.removeLast(hits.count - limit) }

        let elapsedMs = (CFAbsoluteTimeGetCurrent() - start) * 1000
        print(String(
            format: "[CityDatabase] nearby r=%.0fkm → %d cities in %.2fms",
            radiusKm, hits.count, elapsedMs
        ))
        return hits.map(\.city)
    }

    /// Prefix search over `asciiName` (diacritic-insensitive), heaviest first.
    /// The query is folded to ASCII so "São" matches the asciiName "Sao Paulo".
    func search(query: String, limit: Int) -> [City] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 2, limit > 0, let db = handle() else { return [] }

        let folded = trimmed.folding(options: .diacriticInsensitive, locale: nil)
        let pattern = folded + "%"

        let sql = """
        SELECT geonameId, name, asciiName, countryCode, lat, lon, population
        FROM city WHERE asciiName LIKE ? COLLATE NOCASE
        ORDER BY population DESC LIMIT ?;
        """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            logError("search prepare")
            return []
        }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, pattern, -1, Self.transient)
        sqlite3_bind_int(stmt, 2, Int32(limit))

        var results: [City] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            results.append(readCity(stmt))
        }
        return results
    }

    /// Nearest city to `coordinate`, searching outward in growing rings. Returns
    /// `nil` only when nothing lies within the widest ring (≈800 km) — e.g. the
    /// open ocean far from any land.
    func nearestCity(to coordinate: CLLocationCoordinate2D) -> City? {
        for radiusKm in [50.0, 100, 200, 400, 800] {
            if let nearest = nearby(center: coordinate, radiusKm: radiusKm, limit: 1).first {
                return nearest
            }
        }
        return nil
    }

    // MARK: - Handle

    private func handle() -> OpaquePointer? {
        if openAttempted { return db }
        openAttempted = true

        guard let resolved = path
            ?? Bundle.main.url(forResource: "cities", withExtension: "sqlite")?.path
        else {
            print("[CityDatabase] cities.sqlite missing from bundle")
            return nil
        }

        var handle: OpaquePointer?
        let flags = SQLITE_OPEN_READONLY | SQLITE_OPEN_NOMUTEX
        if sqlite3_open_v2(resolved, &handle, flags, nil) == SQLITE_OK {
            db = handle
        } else {
            let message = handle.map { String(cString: sqlite3_errmsg($0)) } ?? "unknown"
            print("[CityDatabase] open failed: \(message)")
            sqlite3_close(handle)
            db = nil
        }
        return db
    }

    // MARK: - Row mapping

    private func readCity(_ stmt: OpaquePointer?) -> City {
        City(
            geonameId: Int(sqlite3_column_int64(stmt, 0)),
            name: Self.text(stmt, 1),
            asciiName: Self.text(stmt, 2),
            countryCode: Self.text(stmt, 3),
            lat: sqlite3_column_double(stmt, 4),
            lon: sqlite3_column_double(stmt, 5),
            population: Int(sqlite3_column_int64(stmt, 6))
        )
    }

    private func logError(_ context: String) {
        let message = db.map { String(cString: sqlite3_errmsg($0)) } ?? "no handle"
        print("[CityDatabase] \(context): \(message)")
    }

    private static func text(_ stmt: OpaquePointer?, _ column: Int32) -> String {
        guard let cString = sqlite3_column_text(stmt, column) else { return "" }
        return String(cString: cString)
    }

    /// SQLITE_TRANSIENT — tells SQLite to copy the bound string immediately.
    private static let transient = unsafeBitCast(
        -1, to: sqlite3_destructor_type.self
    )
}
