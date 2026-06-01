import SwiftUI

/// The user's intention for a focus session — what they came aboard to do.
/// Coexists with `FocusScenario` (the visual environment): mode = intent,
/// scenario = scenery.
enum FocusMode: String, CaseIterable, Identifiable, Codable, Hashable {
    case focus
    case work
    case meditate
    case read
    case exercise

    var id: String { rawValue }

    var displayKey: String { "focusMode.\(rawValue)" }

    var symbol: String {
        switch self {
        case .focus:    return "scope"
        case .work:     return "laptopcomputer"
        case .meditate: return "leaf.fill"
        case .read:     return "book.fill"
        case .exercise: return "figure.run"
        }
    }

    var tint: Color {
        switch self {
        case .focus:    return Color(hex: UInt32(0xC5D5C0)) // sage
        case .work:     return Color(hex: UInt32(0xC5C5E0)) // lavender
        case .meditate: return Color(hex: UInt32(0xB8D5C5)) // mint
        case .read:     return Color(hex: UInt32(0xD5D0B8)) // cream
        case .exercise: return Color(hex: UInt32(0xE0C5D0)) // blush
        }
    }
}

/// A user-defined focus mode created via the "+" sheet.
/// Persisted by `FocusModeStore` in UserDefaults.
struct CustomFocusMode: Codable, Hashable, Identifiable {
    var id: UUID
    var name: String
    var symbol: String   // SF Symbol
    var tintHex: UInt32  // packed RGB, as used by `Color(hex:)`

    var tint: Color { Color(hex: UInt32(tintHex)) }

    init(id: UUID = UUID(), name: String, symbol: String, tintHex: UInt32) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.tintHex = tintHex
    }
}