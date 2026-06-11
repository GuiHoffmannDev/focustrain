import SwiftUI
import UIKit

extension MapStyle {
    /// terra/satellite carry dark imagery in *both* schemes, so chrome drawn over
    /// them must stay light regardless of appearance. mono/standard follow the
    /// scheme (their tiles flip light/dark with the system).
    func usesDarkChrome(for scheme: ColorScheme) -> Bool {
        scheme == .dark || self == .terra || self == .satellite
    }

    /// The UIKit chrome palette for this style under the given scheme.
    func chromeColors(for scheme: ColorScheme) -> MapChromeColors {
        usesDarkChrome(for: scheme) ? .dark : .light
    }
}

/// Static UIKit colours for chrome drawn *inside* the maps — overlay renderers,
/// annotation layers, and rasterised dot images. These can't use a dynamic
/// `UIColor` provider reliably (CGColor / UIImage snapshot the resolved value),
/// so the right set is chosen by hand via `usesDarkChrome` and re-applied on the
/// scheme flip (see the representables' `updateUIView`).
struct MapChromeColors {
    let routeLine: UIColor       // RouteMapView live polyline
    let journeyLine: UIColor     // JourneyMapView cumulative polylines
    let ringStroke: UIColor      // DestinationMapView duration ring
    let ringFill: UIColor
    let pinBorder: UIColor       // solid station disc border + solid pulse
    let pinGhostBorder: UIColor  // ghost station disc border
    let endpointStroke: UIColor  // route endpoint dot stroke + filled fill
    let endpointHole: UIColor    // hollow endpoint dot centre
    let originDot: UIColor       // DestinationMapView origin dot
    let trainBorder: UIColor
    let trainGlow: UIColor
    let trainGlowOpacity: Float

    /// Exact current values — the locked dark baseline.
    static let dark = MapChromeColors(
        routeLine:        .white,
        journeyLine:      UIColor.white.withAlphaComponent(0.85),
        ringStroke:       UIColor.white.withAlphaComponent(0.5),
        ringFill:         UIColor.white.withAlphaComponent(0.04),
        pinBorder:        .white,
        pinGhostBorder:   UIColor.white.withAlphaComponent(0.4),
        endpointStroke:   .white,
        endpointHole:     UIColor(white: 0.06, alpha: 0.9),
        originDot:        .white,
        trainBorder:      .white,
        trainGlow:        .white,
        trainGlowOpacity: 0.9
    )

    /// Charcoal chrome for light maps. Pin/train *bodies* stay dark (they read as
    /// physical markers); only their rims, glow, lines and dots move to charcoal.
    static let light = MapChromeColors(
        routeLine:        UIColor(hex: 0x333333),
        journeyLine:      UIColor(hex: 0x333333, alpha: 0.85),
        ringStroke:       UIColor(hex: 0x333333, alpha: 0.5),
        ringFill:         UIColor(hex: 0x333333, alpha: 0.08),
        pinBorder:        UIColor(hex: 0x333333),
        pinGhostBorder:   UIColor(hex: 0x333333, alpha: 0.4),
        endpointStroke:   UIColor(hex: 0x1A1A1A),
        endpointHole:     UIColor(white: 1.0, alpha: 0.9),
        originDot:        UIColor(hex: 0x1A1A1A),
        trainBorder:      UIColor(hex: 0x333333),
        trainGlow:        .black,
        trainGlowOpacity: 0.25
    )
}
