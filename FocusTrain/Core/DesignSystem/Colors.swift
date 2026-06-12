import SwiftUI
import UIKit

extension Color {
    init(hex: UInt32, opacity: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}

extension UIColor {
    /// Hex → sRGB UIColor. Mirrors `Color(hex:opacity:)` so dynamic tokens
    /// resolve byte-for-byte identical to the old static `Color(hex:)` values.
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        let r = CGFloat((hex >> 16) & 0xFF) / 255.0
        let g = CGFloat((hex >> 8) & 0xFF) / 255.0
        let b = CGFloat(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }
}

extension Color {
    /// A token that resolves light/dark from the trait environment.
    ///
    /// The dark branch must reproduce the app's previous static hex byte-for-byte
    /// (dark is the locked baseline). The light branch is the new value.
    ///
    /// Gotchas (do not break these):
    /// - `.opacity(x)` over a dynamic token works and re-resolves live — use it
    ///   when the alpha is identical in both schemes; bake the alpha into the
    ///   provider (`lightAlpha`/`darkAlpha`) when it differs.
    /// - Never pull `cgColor` / `UIColor(Color)` out of a dynamic token: that
    ///   snapshots one scheme and freezes it. Keep dynamic tokens as `Color`.
    /// - `MKOverlayRenderer` / `CALayer` / `UIImage` do not honour a dynamic
    ///   provider reliably — use static resolved colors there and re-apply them
    ///   on the scheme flip (see `MapChrome`).
    init(light: UInt32, lightAlpha: CGFloat = 1,
         dark: UInt32,  darkAlpha: CGFloat = 1) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: dark,  alpha: darkAlpha)
                : UIColor(hex: light, alpha: lightAlpha)
        })
    }

    /// Scheme-adaptive grey built from two `white:` luminances. Keeps the light
    /// branch byte-identical to a plain `Color(white:)` (no hex round-trip), so
    /// existing greys can flip to dark mode without shifting in light mode.
    init(whiteLight: Double, whiteDark: Double) {
        self.init(uiColor: UIColor { traits in
            UIColor(white: traits.userInterfaceStyle == .dark ? whiteDark : whiteLight,
                    alpha: 1)
        })
    }
}

enum FT {
    enum Palette {
        // Absolute primitives — never adapt.
        static let black         = Color(hex: 0x000000)
        static let white         = Color(hex: 0xFFFFFF)

        // Adaptive tokens. Dark = previous static hex (locked baseline); light = new.
        static let bgPrimary     = Color(light: 0xF5F5F7, dark: 0x000000)
        static let bgElevated    = Color(light: 0xFFFFFF, dark: 0x0F1729)

        static let brandRail     = Color(light: 0x333333, dark: 0xFFFFFF)
        static let brandBrass    = Color(hex: 0xE0A458)

        static let textPrimary   = Color(light: 0x1A1A1A, dark: 0xFFFFFF)
        static let textSecondary = Color(light: 0x5B616B, dark: 0x9CA3AF)
        static let textMuted     = Color(light: 0x8E939B, dark: 0x6B7280)

        static let surfaceLight  = Color(hex: 0xF4F4F6)
        static let ink           = Color(hex: 0x1A1A2E)

        static let success       = Color(hex: 0x22C55E)
        static let railLine      = Color(light: 0x333333, dark: 0xFFFFFF)

        static let emerald       = Color(hex: 0x2ECC71)
        static let indigo        = Color(hex: 0x6C7AE0)

        static let gray100       = Color(hex: 0xF5F5F5)
        static let gray400       = Color(hex: 0x9CA3AF)
        static let gray800       = Color(light: 0xE5E6E8, dark: 0x1E1E1E)

        static let greenDark     = Color(hex: 0x1B5E20)

        // MARK: Semantic adaptive tokens (new in light-mode work)

        /// Rim of idle glass, faint dividers (6–8%). White-on-dark / black-on-light.
        static let strokeHairline   = Color(light: 0x000000, lightAlpha: 0.10,
                                            dark:  0xFFFFFF, darkAlpha:  0.08)
        /// Stroke around frosted cards (FTGlassCardButton).
        static let strokeCard       = Color(light: 0x000000, lightAlpha: 0.08,
                                            dark:  0xFFFFFF, darkAlpha:  0.10)
        /// Vignettes / scrim gradients off-map. Matches `bgPrimary`.
        static let scrim            = Color(light: 0xF5F5F7, dark: 0x000000)
        /// Soft chrome shadow — lighter in light mode so it does not muddy.
        static let shadowSoft       = Color(light: 0x000000, lightAlpha: 0.15,
                                            dark:  0x000000, darkAlpha:  0.40)
        /// Fill of an active session control (toggle-on).
        static let controlActiveTint  = Color(light: 0x1A1A2E, lightAlpha: 0.75,
                                              dark:  0xFFFFFF, darkAlpha:  0.75)
        /// Glyph on an active control + foreground of the primary CTA.
        static let controlActiveGlyph = Color(light: 0xFFFFFF, dark: 0x1A1A2E)
        /// Solid fill of the selected-segment thumb (SessionSegmentedPill).
        /// Deliberately opaque — the reference design uses a solid block;
        /// standalone toggles keep the translucent `controlActiveTint`.
        static let controlThumb       = Color(light: 0x1A1A2E, dark: 0xFFFFFF)
        /// Fill of a selected filter chip (History/Trends).
        static let chipSelectedTint   = Color(light: 0x1A1A2E, lightAlpha: 0.75,
                                              dark:  0xFFFFFF, darkAlpha:  0.75)
        /// Foreground of a selected filter chip (was exact `.black`).
        static let chipSelectedFg     = Color(light: 0xFFFFFF, dark: 0x000000)

        /// Boarding-pass ticket (the tear-to-board pass). The card inverts by
        /// scheme: a near-black card with light ink in light mode (the locked
        /// baseline), a near-white card with dark ink in dark mode — so the
        /// ticket always reads as a high-contrast object against the page.
        /// Each token's light branch is the previous `Color(white:)` value;
        /// the dark branch is its luminance inverse (1 − value).
        enum Ticket {
            static let card        = Color(whiteLight: 0.10, whiteDark: 0.90)
            static let outline     = Color(whiteLight: 0.18, whiteDark: 0.82)
            static let ink         = Color(whiteLight: 1.00, whiteDark: 0.00)  // primary text/barcode
            static let inkStrong   = Color(whiteLight: 0.70, whiteDark: 0.30)  // duration label
            static let inkMuted    = Color(whiteLight: 0.55, whiteDark: 0.45)  // headers, city names
            static let inkFaint    = Color(whiteLight: 0.50, whiteDark: 0.50)  // field labels (mid-grey)
            static let hint        = Color(whiteLight: 0.60, whiteDark: 0.40)  // tear hint
            static let perforation = Color(whiteLight: 0.45, whiteDark: 0.55)
            static let mapTint     = Color(whiteLight: 0.42, whiteDark: 0.58)  // dot-matrix watermark
        }

        enum Scenario {
            static let sage     = Color(hex: 0xC5D5C0)
            static let lavender = Color(hex: 0xC5C5E0)
            static let blush    = Color(hex: 0xE0C5D0)
            static let cream    = Color(hex: 0xD5D0B8)
            static let mint     = Color(hex: 0xB8D5C5)
        }
    }
}
