import SwiftUI

/// Vertical capsule container that stacks side-control buttons.
/// Used in pairs on the left and right edges of `SessionView`.
struct SessionControlPill<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 6) {
            content()
        }
        .environment(\.sessionControlGrouped, true)
        .padding(.vertical, 6)
        .padding(.horizontal, 6)
        .background {
            Capsule()
                .fill(.clear)
                .ftGlassCapsule(liquid: true)
        }
    }
}

#Preview("Two buttons") {
    ZStack {
        FT.Palette.bgElevated.ignoresSafeArea()
        SessionControlPill {
            SessionControlButton(systemName: "pause.fill", state: .disabled, accessibilityLabel: "Pause") {}
            SessionControlButton(systemName: "music.note", state: .idle, accessibilityLabel: "Music") {}
        }
    }
}

#Preview("Three buttons") {
    ZStack {
        FT.Palette.bgElevated.ignoresSafeArea()
        SessionControlPill {
            SessionControlButton(systemName: "moon.zzz.fill", state: .active, accessibilityLabel: "Tunnel") {}
            SessionControlButton(systemName: "scope", state: .idle, accessibilityLabel: "Follow") {}
            SessionControlButton(systemName: "map", state: .idle, accessibilityLabel: "Map style") {}
        }
    }
}
