import SwiftUI
import Observation

/// Full-screen overlay that lets the traveller browse ambient sounds, toggle
/// the master switch, adjust volume, and pick an AirPlay route. Replaces the
/// old SoundSheet — appears with a pure fade over the SessionView (no drag
/// handle, no sheet chrome) to match the live-ride immersive feel.
struct SoundOverlay: View {
    @Bindable var sound: AmbientSoundController
    let onDismiss: () -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.regularMaterial)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
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
                                        sound.selected = (sound.selected == ambient) ? nil : ambient
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
            }
        }
    }

    private var topBar: some View {
        HStack {
            Spacer()
            closeButton
        }
        .padding(.horizontal, FT.Layout.sideMargin)
        .padding(.top, 8)
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
            SoundVolumePill(volume: $sound.volume)
                .frame(maxWidth: 240)
            Spacer(minLength: 0)
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
        FTGlassIconButton(
            systemName: "xmark",
            size: 30,
            iconSize: 14,
            foreground: FT.Palette.textPrimary,
            accessibilityLabel: "session.sound.close",
            action: onDismiss
        )
        .accessibilityLabel(Text(NSLocalizedString("session.sound.close", comment: "")))
    }
}

#Preview {
    SoundOverlay(sound: AmbientSoundController(), onDismiss: {})
}
