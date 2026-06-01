import SwiftUI

extension FT {
    enum Typography {
        static let displayXL    = Font.system(size: 52, weight: .bold,     design: .default)
        static let displayL     = Font.system(size: 44, weight: .bold,     design: .default)
        static let displayM     = Font.system(size: 40, weight: .bold,     design: .default)

        static let heroTitle    = Font.system(size: 36, weight: .bold,     design: .default)
        static let sectionTitle = Font.system(size: 28, weight: .bold,     design: .default)

        static let contextLine  = Font.system(size: 15, weight: .medium,   design: .default)
        static let body         = Font.system(size: 17, weight: .regular,  design: .default)
        static let caption      = Font.system(size: 13, weight: .regular,  design: .default)
        static let button       = Font.system(size: 17, weight: .semibold, design: .default)
        static let badge        = Font.system(size: 14, weight: .bold,     design: .default)
        static let ticketField  = Font.system(size: 13, weight: .medium,   design: .monospaced)
    }

    enum Layout {
        static let sideMargin: CGFloat       = 24
        static let ctaHeight: CGFloat        = 64
        static let cornerRadius: CGFloat     = 28
        static let cardRadius: CGFloat       = 22
        static let spacing: CGFloat          = 8
        static let stepBarWidth: CGFloat     = 48
        static let stepBarHeight: CGFloat    = 4
        static let stepSegments: Int         = 4
    }
}
