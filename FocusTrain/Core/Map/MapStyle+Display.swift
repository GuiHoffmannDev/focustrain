import Foundation

extension MapStyle {
    var displayKey: String {
        "mapstyle.\(rawValue).title"
    }

    var symbol: String {
        switch self {
        case .monochrome: return "circle.lefthalf.filled"
        case .terra:      return "mountain.2"
        case .standard:   return "map"
        case .satellite:  return "globe.americas"
        }
    }
}
