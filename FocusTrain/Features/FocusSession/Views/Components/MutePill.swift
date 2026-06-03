import SwiftUI

/// Long glass pill that toggles the session-ephemeral mute. Sits next to
/// the AirPlay button in the SoundSheet's controls row, taking the
/// remaining horizontal width.
struct MutePill: View {
    @Binding var isMuted: Bool

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
                isMuted.toggle()
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.slash")
                    .font(.system(size: 14, weight: .bold))
                Text(NSLocalizedString(
                    isMuted ? "session.sound.muted" : "session.sound.mute",
                    comment: ""
                ))
                .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(FT.Palette.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background {
                Capsule().fill(.clear).glassEffect(.regular, in: Capsule())
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("Mute"))
        .accessibilityValue(isMuted ? "muted" : "unmuted")
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    VStack(spacing: 12) {
        MutePill(isMuted: .constant(false))
        MutePill(isMuted: .constant(true))
    }
    .padding()
    .background(FT.Palette.bgElevated)
}
