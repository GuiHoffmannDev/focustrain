import SwiftUI

/// Wraps the in-ride music/scenario picker. Owns the `session.updateScenario`
/// side-effect so the parent view doesn't need to thread it.
struct SessionMusicMenu: View {
    @Binding var scenario: FocusScenario
    var onSelect: (FocusScenario) -> Void

    var body: some View {
        Menu {
            ForEach(FocusScenario.allCases) { option in
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    scenario = option
                    onSelect(option)
                } label: {
                    Label {
                        Text(LocalizedStringKey(option.displayKey))
                    } icon: {
                        Image(systemName: scenario == option ? "checkmark" : option.symbol)
                    }
                }
            }
        } label: {
            Image(systemName: "music.note")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(FT.Palette.white)
                .frame(width: 40, height: 40)
                .background {
                    Color.clear.glassEffect(.regular, in: Circle())
                }
        }
        .accessibilityLabel(Text(NSLocalizedString("session.music.a11y", comment: "")))
    }
}
