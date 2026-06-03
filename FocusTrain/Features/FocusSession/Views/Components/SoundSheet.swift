import SwiftUI
import Observation

/// Modal that lets the traveller browse ambient sounds, toggle the master
/// switch, mute temporarily, and pick an AirPlay route. Phase 3 owns the
/// surface; Phase 4 will hang real audio off `sound.isPlaying`.
struct SoundSheet: View {
    @Bindable var sound: AmbientSoundController
    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    header
                    controlsRow
                    sectionHeader(key: "session.sound.section.white")
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(AmbientSound.allCases.filter { $0.category == .whiteNoise }) { ambient in
                            AmbientSoundCard(
                                sound: ambient,
                                isOn: sound.selected == ambient,
                                isEnabled: sound.isEnabled,
                                onTap: {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
                                        sound.selected = (sound.selected == ambient) ? nil : ambient
                                    }
                                }
                            )
                        }
                    }
                    sectionHeader(key: "session.sound.section.focus")
                    LazyVGrid(columns: columns, spacing: 12) {
                        ComingSoonCard()
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, FT.Layout.sideMargin)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    closeButton
                }
            }
        }
    }

    private var header: some View {
        HStack {
            Text(NSLocalizedString("session.sound.title", comment: ""))
                .font(FT.Typography.sectionTitle)
                .foregroundStyle(FT.Palette.textPrimary)
            Spacer()
            SoundMasterPill(isEnabled: $sound.isEnabled)
        }
    }

    private var controlsRow: some View {
        HStack(spacing: 12) {
            AirPlayButton()
            MutePill(isMuted: $sound.isMuted)
        }
    }

    private func sectionHeader(key: String) -> some View {
        HStack {
            Text(NSLocalizedString(key, comment: ""))
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(FT.Palette.textSecondary)
                .accessibilityAddTraits(.isHeader)
            Spacer()
        }
        .padding(.top, 4)
    }

    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(FT.Palette.textPrimary)
                .frame(width: 30, height: 30)
                .background(Circle().fill(FT.Palette.bgElevated.opacity(0.6)))
        }
        .accessibilityLabel(Text(NSLocalizedString("session.sound.close", comment: "")))
    }
}

#Preview {
    SoundSheet(sound: AmbientSoundController())
}
