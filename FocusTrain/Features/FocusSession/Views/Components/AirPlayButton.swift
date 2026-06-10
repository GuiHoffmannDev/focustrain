import SwiftUI
import AVKit

/// 40pt circular button that opens the system AirPlay route picker. Wraps
/// AVRoutePickerView so it can sit inside SwiftUI alongside the other
/// 40pt glass controls.
struct AirPlayButton: View {
    var body: some View {
        RoutePicker()
            .frame(width: 40, height: 40)
            .background {
                Color.clear.ftGlassCircle(interactive: true)
            }
            .accessibilityLabel(Text(NSLocalizedString("session.sound.airplay.a11y", comment: "")))
            .accessibilityAddTraits(.isButton)
    }

    private struct RoutePicker: UIViewRepresentable {
        func makeUIView(context: Context) -> AVRoutePickerView {
            let v = AVRoutePickerView()
            // UIKit view: a dynamic UIColor (not a SwiftUI token) so the glyph
            // re-resolves on the scheme flip. Mirrors `textPrimary`.
            let glyph = UIColor { $0.userInterfaceStyle == .dark
                ? UIColor(hex: 0xFFFFFF) : UIColor(hex: 0x1A1A1A) }
            v.tintColor = glyph
            v.activeTintColor = glyph
            v.prioritizesVideoDevices = false
            v.backgroundColor = .clear
            return v
        }

        func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
    }
}

#Preview {
    AirPlayButton()
        .padding()
        .background(FT.Palette.bgElevated)
}
