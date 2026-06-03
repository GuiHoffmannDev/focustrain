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
                Color.clear.glassEffect(.regular, in: Circle())
            }
            .accessibilityLabel(Text(NSLocalizedString("session.sound.airplay.a11y", comment: "")))
            .accessibilityAddTraits(.isButton)
    }

    private struct RoutePicker: UIViewRepresentable {
        func makeUIView(context: Context) -> AVRoutePickerView {
            let v = AVRoutePickerView()
            v.tintColor = UIColor.white
            v.activeTintColor = UIColor.white
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
