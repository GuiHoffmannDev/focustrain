import SwiftUI

enum AmbientSoundCategory {
    case whiteNoise
    case focusSound
}

enum AmbientSound: String, CaseIterable, Identifiable {
    case airplane = "airplane"
    case raindrop = "raindrop"
    case ocean    = "ocean"
    case forest   = "forest"

    var id: String { rawValue }

    var displayKey: String { "sound.\(rawValue).title" }

    var symbol: String {
        switch self {
        case .airplane: return "airplane"
        case .raindrop: return "cloud.rain.fill"
        case .ocean:    return "water.waves"
        case .forest:   return "tree.fill"
        }
    }

    var gradient: [Color] {
        [FT.Palette.brandBrass, Color(hex: 0xB87A3C)]
    }

    var category: AmbientSoundCategory {
        switch self {
        case .airplane, .raindrop, .ocean, .forest: return .whiteNoise
        }
    }
}
