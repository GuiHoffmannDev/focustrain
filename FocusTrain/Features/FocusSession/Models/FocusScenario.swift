import SwiftUI

enum FocusScenario: String, CaseIterable, Identifiable {
    case forest    = "forest"
    case mountain  = "mountain"
    case coast     = "coast"
    case desert    = "desert"
    case meadow    = "meadow"

    var id: String { rawValue }

    var displayKey: String { "scenario.\(rawValue).title" }
    var subtitleKey: String { "scenario.\(rawValue).subtitle" }

    var tint: Color {
        switch self {
        case .forest:   return FT.Palette.Scenario.sage
        case .mountain: return FT.Palette.Scenario.lavender
        case .coast:    return FT.Palette.Scenario.mint
        case .desert:   return FT.Palette.Scenario.cream
        case .meadow:   return FT.Palette.Scenario.blush
        }
    }

    var symbol: String {
        switch self {
        case .forest:   return "tree.fill"
        case .mountain: return "mountain.2.fill"
        case .coast:    return "water.waves"
        case .desert:   return "sun.max.fill"
        case .meadow:   return "leaf.fill"
        }
    }
}
