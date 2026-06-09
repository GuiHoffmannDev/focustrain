import SwiftUI

enum AmbientSoundCategory {
    case whiteNoise
    case focusSound
}

enum AmbientSound: String, CaseIterable, Identifiable {
    case train    = "train"
    case raindrop = "raindrop"
    case ocean    = "ocean"
    case forest   = "forest"

    var id: String { rawValue }

    var displayKey: String { "sound.\(rawValue).title" }

    var symbol: String {
        switch self {
        case .train:    return "train.side.front.car"
        case .raindrop: return "cloud.rain.fill"
        case .ocean:    return "water.waves"
        case .forest:   return "tree.fill"
        }
    }

    var gradient: [Color] {
        switch self {
        case .train:    return [FT.Palette.brandBrass, Color(hex: 0xB87A3C)]
        case .raindrop: return [Color(hex: 0x60A5FA), Color(hex: 0x2563EB)]
        case .ocean:    return [Color(hex: 0x67E8F9), Color(hex: 0x06B6D4)]
        case .forest:   return [Color(hex: 0x86EFAC), Color(hex: 0x16A34A)]
        }
    }

    /// Single saturated colour used to tint UI surfaces (e.g. the session
    /// music button's Liquid Glass). Matches the deep end of `gradient`.
    var tint: Color {
        switch self {
        case .train:    return FT.Palette.brandBrass
        case .raindrop: return Color(hex: 0x2563EB)
        case .ocean:    return Color(hex: 0x06B6D4)
        case .forest:   return Color(hex: 0x16A34A)
        }
    }

    var category: AmbientSoundCategory {
        switch self {
        case .train, .raindrop, .ocean, .forest: return .whiteNoise
        }
    }
}
