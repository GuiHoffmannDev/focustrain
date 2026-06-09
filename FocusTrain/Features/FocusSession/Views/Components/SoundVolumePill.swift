import SwiftUI

/// Long glass capsule with a blue fill proportional to volume. Replaces the
/// session-ephemeral MutePill — `volume == 0` is the mute state. Drag along
/// the pill to set volume; light haptic fires when crossing the 0 or 1 edge.
struct SoundVolumePill: View {
    @Binding var volume: Double

    @State private var lastEdgeHaptic: Edge?

    private enum Edge { case low, high }

    private let height: CGFloat = 52
    private let fill = Color(hex: 0x3B82F6).opacity(0.55)

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.clear)
                    .ftGlassCapsule(interactive: true)

                Capsule()
                    .fill(fill)
                    .frame(width: max(height, geo.size.width * clampedVolume))
                    .blendMode(.plusLighter)

                HStack {
                    Image(systemName: volume > 0 ? "speaker.wave.2.fill" : "speaker.slash.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(FT.Palette.textPrimary)
                        .padding(.leading, 18)
                    Spacer()
                }
                .frame(height: height)
            }
            .frame(height: height)
            .contentShape(Capsule())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let raw = value.location.x / geo.size.width
                        let clamped = min(max(raw, 0), 1)
                        volume = clamped
                        triggerEdgeHapticIfNeeded(clamped)
                    }
                    .onEnded { _ in
                        lastEdgeHaptic = nil
                    }
            )
        }
        .frame(height: height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(NSLocalizedString("session.sound.volume", comment: "")))
        .accessibilityValue(Text("\(Int(clampedVolume * 100)) percent"))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: volume = min(volume + 0.1, 1)
            case .decrement: volume = max(volume - 0.1, 0)
            @unknown default: break
            }
        }
    }

    private var clampedVolume: Double { min(max(volume, 0), 1) }

    private func triggerEdgeHapticIfNeeded(_ value: Double) {
        let edge: Edge?
        if value <= 0.001 { edge = .low }
        else if value >= 0.999 { edge = .high }
        else { edge = nil }

        if edge != nil, edge != lastEdgeHaptic {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        lastEdgeHaptic = edge
    }
}

#Preview {
    VStack(spacing: 12) {
        SoundVolumePill(volume: .constant(0))
        SoundVolumePill(volume: .constant(0.5))
        SoundVolumePill(volume: .constant(1))
    }
    .padding()
    .background(FT.Palette.bgElevated)
}
