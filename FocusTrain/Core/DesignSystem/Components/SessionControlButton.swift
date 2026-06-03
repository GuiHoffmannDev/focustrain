import SwiftUI

/// 40pt circular control used inside `SessionControlPill`. Three states:
///   • idle     — translucent dark fill, white glyph.
///   • active   — solid white fill, ink glyph. (Toggle-on visual.)
///   • disabled — idle styling at 0.4 opacity, hit testing off.
struct SessionControlButton: View {
    enum State {
        case idle
        case active
        case disabled
    }

    let systemName: String
    let state: State
    let action: () -> Void
    var accessibilityLabel: String
    var accessibilityValue: String? = nil

    init(
        systemName: String,
        state: State,
        accessibilityLabel: String,
        accessibilityValue: String? = nil,
        action: @escaping () -> Void
    ) {
        self.systemName = systemName
        self.state = state
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityValue = accessibilityValue
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(glyphColor)
                .frame(width: 40, height: 40)
                .background {
                    backgroundSurface
                }
        }
        .buttonStyle(.plain)
        .disabled(state == .disabled)
        .opacity(state == .disabled ? 0.4 : 1.0)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(accessibilityValue ?? "")
    }

    @ViewBuilder
    private var backgroundSurface: some View {
        switch state {
        case .active:
            Circle().fill(FT.Palette.white)
        case .idle, .disabled:
            Circle()
                .fill(.clear)
                .glassEffect(.regular, in: Circle())
        }
    }

    private var glyphColor: Color {
        switch state {
        case .active:   return FT.Palette.ink
        case .idle:     return FT.Palette.white
        case .disabled: return FT.Palette.white
        }
    }
}

#Preview("States") {
    HStack(spacing: 12) {
        SessionControlButton(systemName: "moon", state: .idle, accessibilityLabel: "Tunnel") {}
        SessionControlButton(systemName: "moon.zzz.fill", state: .active, accessibilityLabel: "Tunnel") {}
        SessionControlButton(systemName: "pause.fill", state: .disabled, accessibilityLabel: "Pause") {}
    }
    .padding()
    .background(FT.Palette.bgElevated)
}
