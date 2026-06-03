import SwiftUI

/// Compact pill that sits in the SoundSheet's header row and toggles the
/// app's durable "Sound is allowed" preference. Active state is the
/// success-green from the palette; inactive falls back to glass.
struct SoundMasterPill: View {
    @Binding var isEnabled: Bool

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
                isEnabled.toggle()
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "music.note")
                    .font(.system(size: 12, weight: .bold))
                Text(NSLocalizedString(
                    isEnabled ? "session.sound.master.on" : "session.sound.master.off",
                    comment: ""
                ))
                .font(.system(size: 12, weight: .bold))
            }
            .foregroundStyle(isEnabled ? FT.Palette.white : FT.Palette.textSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background {
                if isEnabled {
                    Capsule().fill(FT.Palette.success)
                } else {
                    Capsule().fill(.clear).glassEffect(.regular, in: Capsule())
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("Sound"))
        .accessibilityValue(isEnabled ? "on" : "off")
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    HStack(spacing: 12) {
        SoundMasterPill(isEnabled: .constant(true))
        SoundMasterPill(isEnabled: .constant(false))
    }
    .padding()
    .background(FT.Palette.bgElevated)
}
