import SwiftUI

/// 1:1 card used in the SoundSheet's grid. Title top-leading, faint
/// background glyph filling the lower-right, ON/OFF label + dot
/// bottom-trailing. Pure presentation — the parent owns selection logic.
struct AmbientSoundCard: View {
    let sound: AmbientSound
    let isOn: Bool
    let isEnabled: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                background
                content
            }
            .aspectRatio(1, contentMode: .fit)
            .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
        .opacity(isEnabled ? 1 : 0.5)
        .allowsHitTesting(isEnabled)
        .animation(.spring(response: 0.4, dampingFraction: 0.82), value: isOn)
        .accessibilityLabel(Text(LocalizedStringKey(sound.displayKey)))
        .accessibilityValue(isOn ? "on" : "off")
        .accessibilityHint(Text(isOn ? "Double tap to turn off" : "Double tap to select"))
        .accessibilityAddTraits(.isButton)
    }

    @ViewBuilder
    private var background: some View {
        if isOn {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.clear)
                .ftGlassRounded(cornerRadius: 20, interactive: true, tint: sound.tint.opacity(0.45))
                .overlay(
                    LinearGradient(
                        colors: sound.gradient.map { $0.opacity(0.35) },
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                )
                .overlay { glyph(opacity: 0.18) }
        } else {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.clear)
                .ftGlassRounded(cornerRadius: 20, interactive: true)
                .overlay { glyph(opacity: 0.12) }
        }
    }

    private func glyph(opacity: Double) -> some View {
        Image(systemName: sound.symbol)
            .font(.system(size: 90, weight: .semibold))
            .foregroundStyle(FT.Palette.textPrimary.opacity(opacity))
            .rotationEffect(.degrees(-12))
            .offset(x: 18, y: 18)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .allowsHitTesting(false)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(LocalizedStringKey(sound.displayKey))
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(FT.Palette.textPrimary)
                .lineLimit(2)
            Spacer(minLength: 0)
            HStack(spacing: 6) {
                Spacer()
                Circle()
                    .fill(isOn ? FT.Palette.textPrimary : FT.Palette.textMuted)
                    .frame(width: 6, height: 6)
                Text(NSLocalizedString(isOn ? "sound.state.on" : "sound.state.off", comment: ""))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(isOn ? FT.Palette.textPrimary : FT.Palette.textMuted)
            }
        }
        .padding(14)
    }
}

/// Placeholder card for the "Focus Sound" section. Non-interactive
/// disabled visual until Phase 4+ delivers the real focus tracks.
struct ComingSoonCard: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.clear)
                .ftGlassRounded(cornerRadius: 20)
                .overlay {
                    Image(systemName: "door.left.hand.closed")
                        .font(.system(size: 90, weight: .semibold))
                        .foregroundStyle(FT.Palette.textPrimary.opacity(0.10))
                        .rotationEffect(.degrees(-12))
                        .offset(x: 18, y: 18)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .allowsHitTesting(false)
                }
            VStack(alignment: .leading, spacing: 0) {
                Text(NSLocalizedString("sound.comingsoon.title", comment: ""))
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(FT.Palette.textPrimary)
                Spacer(minLength: 0)
                HStack(spacing: 6) {
                    Spacer()
                    Circle()
                        .fill(FT.Palette.textMuted)
                        .frame(width: 6, height: 6)
                    Text(NSLocalizedString("sound.state.off", comment: ""))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(FT.Palette.textMuted)
                }
            }
            .padding(14)
        }
        .aspectRatio(1, contentMode: .fit)
        .opacity(0.5)
        .allowsHitTesting(false)
        .accessibilityLabel(Text(NSLocalizedString("sound.comingsoon.title", comment: "")))
        .accessibilityAddTraits(.isStaticText)
    }
}

#Preview("Cards") {
    VStack(spacing: 16) {
        HStack(spacing: 12) {
            AmbientSoundCard(sound: .train, isOn: true, isEnabled: true, onTap: {})
            AmbientSoundCard(sound: .raindrop, isOn: false, isEnabled: true, onTap: {})
        }
        HStack(spacing: 12) {
            AmbientSoundCard(sound: .ocean, isOn: false, isEnabled: false, onTap: {})
            ComingSoonCard()
        }
    }
    .padding()
    .background(FT.Palette.bgElevated)
}
