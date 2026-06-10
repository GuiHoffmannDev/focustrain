import SwiftUI

/// Marks controls rendered inside a `SessionControlPill`. Grouped buttons must
/// not paint their own Liquid Glass: nesting `glassEffect` inside the pill's
/// glass capsule makes the shapes merge and smear the glyphs.
private struct SessionControlGroupedKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var sessionControlGrouped: Bool {
        get { self[SessionControlGroupedKey.self] }
        set { self[SessionControlGroupedKey.self] = newValue }
    }
}

/// 48pt circular control used standalone or inside `SessionControlPill`.
/// Three states:
///   • idle     — plain Liquid Glass, white glyph.
///   • active   — white fill, ink glyph. (Toggle-on visual, e.g. camera/tunnel.)
///   • disabled — idle styling at 0.4 opacity, hit testing off.
///
/// Buttons whose state already reads through the glyph (pause/play) should
/// stay on `.idle` and let the icon swap communicate instead of a fill.
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

    @Environment(\.sessionControlGrouped) private var grouped

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
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(state == .active ? FT.Palette.controlActiveGlyph : FT.Palette.textPrimary)
                .frame(width: 48, height: 48)
                .background {
                    if grouped {
                        // The pill capsule already provides the glass; painting
                        // more glass here would nest and smear. Active keeps a
                        // plain translucent fill so the toggle still reads.
                        if state == .active {
                            Circle()
                                .fill(FT.Palette.controlActiveTint)
                        }
                    } else if state == .active {
                        Circle()
                            .fill(.clear)
                            .ftGlassCircle(interactive: true, tint: FT.Palette.controlActiveTint, liquid: true)
                    } else {
                        Circle()
                            .fill(.clear)
                            .ftGlassCircle(interactive: true, liquid: true)
                    }
                }
                .contentShape(Circle())
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.plain)
        .disabled(state == .disabled)
        .opacity(state == .disabled ? 0.4 : 1.0)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(accessibilityValue ?? "")
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
