import SwiftUI

extension Color {
    init(hex: UInt32, opacity: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}

enum FT {
    enum Palette {
        static let black         = Color(hex: 0x000000)
        static let white         = Color(hex: 0xFFFFFF)

        static let bgPrimary     = Color(hex: 0x000000)
        static let bgElevated    = Color(hex: 0x0F1729)

        static let brandRail     = Color(hex: 0xFFFFFF)
        static let brandBrass    = Color(hex: 0xE0A458)

        static let textPrimary   = Color(hex: 0xFFFFFF)
        static let textSecondary = Color(hex: 0x9CA3AF)
        static let textMuted     = Color(hex: 0x6B7280)

        static let surfaceLight  = Color(hex: 0xF4F4F6)
        static let ink           = Color(hex: 0x1A1A2E)

        static let success       = Color(hex: 0x22C55E)
        static let railLine      = Color(hex: 0xFFFFFF)

        static let emerald       = Color(hex: 0x2ECC71)
        static let indigo        = Color(hex: 0x6C7AE0)

        static let gray100       = Color(hex: 0xF5F5F5)
        static let gray400       = Color(hex: 0x9CA3AF)
        static let gray800       = Color(hex: 0x1E1E1E)

        static let greenDark     = Color(hex: 0x1B5E20)

        enum Scenario {
            static let sage     = Color(hex: 0xC5D5C0)
            static let lavender = Color(hex: 0xC5C5E0)
            static let blush    = Color(hex: 0xE0C5D0)
            static let cream    = Color(hex: 0xD5D0B8)
            static let mint     = Color(hex: 0xB8D5C5)
        }
    }
}
