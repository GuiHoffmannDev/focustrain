import Foundation
import CoreLocation

struct Station: Hashable {
    let code: String
    let city: String
    let lat: Double
    let lon: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}

enum StationPool {
    static let all: [Station] = [
        .init(code: "TYO", city: "Tokyo",         lat: 35.6762,  lon: 139.6503),
        .init(code: "NYC", city: "New York",      lat: 40.7128,  lon: -74.0060),
        .init(code: "PAR", city: "Paris",         lat: 48.8566,  lon: 2.3522),
        .init(code: "LON", city: "London",        lat: 51.5074,  lon: -0.1278),
        .init(code: "SPO", city: "São Paulo",     lat: -23.5505, lon: -46.6333),
        .init(code: "RIO", city: "Rio de Janeiro",lat: -22.9068, lon: -43.1729),
        .init(code: "BER", city: "Berlin",        lat: 52.5200,  lon: 13.4050),
        .init(code: "MAD", city: "Madrid",        lat: 40.4168,  lon: -3.7038),
        .init(code: "ROM", city: "Rome",          lat: 41.9028,  lon: 12.4964),
        .init(code: "AMS", city: "Amsterdam",     lat: 52.3676,  lon: 4.9041),
        .init(code: "LIS", city: "Lisbon",        lat: 38.7223,  lon: -9.1393),
        .init(code: "VIE", city: "Vienna",        lat: 48.2082,  lon: 16.3738),
        .init(code: "PRG", city: "Prague",        lat: 50.0755,  lon: 14.4378),
        .init(code: "CPH", city: "Copenhagen",    lat: 55.6761,  lon: 12.5683),
        .init(code: "STO", city: "Stockholm",     lat: 59.3293,  lon: 18.0686),
        .init(code: "OSL", city: "Oslo",          lat: 59.9139,  lon: 10.7522),
        .init(code: "HEL", city: "Helsinki",      lat: 60.1699,  lon: 24.9384),
        .init(code: "ZRH", city: "Zurich",        lat: 47.3769,  lon: 8.5417),
        .init(code: "IST", city: "Istanbul",      lat: 41.0082,  lon: 28.9784),
        .init(code: "DXB", city: "Dubai",         lat: 25.2048,  lon: 55.2708),
        .init(code: "DOH", city: "Doha",          lat: 25.2854,  lon: 51.5310),
        .init(code: "DEL", city: "Delhi",         lat: 28.6139,  lon: 77.2090),
        .init(code: "BOM", city: "Mumbai",        lat: 19.0760,  lon: 72.8777),
        .init(code: "BKK", city: "Bangkok",       lat: 13.7563,  lon: 100.5018),
        .init(code: "SIN", city: "Singapore",     lat: 1.3521,   lon: 103.8198),
        .init(code: "HKG", city: "Hong Kong",     lat: 22.3193,  lon: 114.1694),
        .init(code: "SHA", city: "Shanghai",      lat: 31.2304,  lon: 121.4737),
        .init(code: "BJS", city: "Beijing",       lat: 39.9042,  lon: 116.4074),
        .init(code: "SEL", city: "Seoul",         lat: 37.5665,  lon: 126.9780),
        .init(code: "OSA", city: "Osaka",         lat: 34.6937,  lon: 135.5023),
        .init(code: "KIX", city: "Kyoto",         lat: 35.0116,  lon: 135.7681),
        .init(code: "MEL", city: "Melbourne",     lat: -37.8136, lon: 144.9631),
        .init(code: "SYD", city: "Sydney",        lat: -33.8688, lon: 151.2093),
        .init(code: "AKL", city: "Auckland",      lat: -36.8485, lon: 174.7633),
        .init(code: "JNB", city: "Johannesburg",  lat: -26.2041, lon: 28.0473),
        .init(code: "CPT", city: "Cape Town",     lat: -33.9249, lon: 18.4241),
        .init(code: "CAI", city: "Cairo",         lat: 30.0444,  lon: 31.2357),
        .init(code: "NBO", city: "Nairobi",       lat: -1.2921,  lon: 36.8219),
        .init(code: "MEX", city: "Mexico City",   lat: 19.4326,  lon: -99.1332),
        .init(code: "BUE", city: "Buenos Aires",  lat: -34.6037, lon: -58.3816),
        .init(code: "SCL", city: "Santiago",      lat: -33.4489, lon: -70.6693),
        .init(code: "LIM", city: "Lima",          lat: -12.0464, lon: -77.0428),
        .init(code: "BOG", city: "Bogotá",        lat: 4.7110,   lon: -74.0721),
        .init(code: "YYZ", city: "Toronto",       lat: 43.6532,  lon: -79.3832),
        .init(code: "YVR", city: "Vancouver",     lat: 49.2827,  lon: -123.1207),
        .init(code: "CHI", city: "Chicago",       lat: 41.8781,  lon: -87.6298),
        .init(code: "LAX", city: "Los Angeles",   lat: 34.0522,  lon: -118.2437),
        .init(code: "SFO", city: "San Francisco", lat: 37.7749,  lon: -122.4194),
        .init(code: "SEA", city: "Seattle",       lat: 47.6062,  lon: -122.3321),
        .init(code: "MIA", city: "Miami",         lat: 25.7617,  lon: -80.1918),
    ]

    static func randomPair() -> (from: Station, to: Station) {
        let shuffled = all.shuffled()
        return (shuffled[0], shuffled[1])
    }

    static func station(forCode code: String) -> Station? {
        all.first { $0.code == code }
    }
}
