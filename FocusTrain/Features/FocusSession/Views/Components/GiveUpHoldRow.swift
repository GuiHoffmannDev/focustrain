import SwiftUI

/// First row of the pause menu — replaces a tap-to-confirm flow with a
/// hold-to-confirm pill. While idle it mimics a normal MenuItemRow (red X
/// circle + "Give up"). On press, the row morphs into a black capsule that
/// fills white from leading to trailing over 2s. Releasing early rewinds the
/// fill; filling completely fires `onCommit` directly.
struct GiveUpHoldRow: View {
    var onCommit: () -> Void

    @State private var isPressing = false
    @State private var progress: CGFloat = 0
    @State private var pendingTicks: [DispatchWorkItem] = []
    @State private var completionWorkItem: DispatchWorkItem?

    private let holdDuration: Double = 2.0
    private let rewindDuration: Double = 0.25
    private let morphDuration: Double = 0.25

    var body: some View {
        ZStack(alignment: .leading) {
            idleContent
                .opacity(isPressing ? 0 : 1)
                .scaleEffect(isPressing ? 0.9 : 1, anchor: .leading)

            holdPill
                .opacity(isPressing ? 1 : 0)
                .scaleEffect(isPressing ? 1 : 0.92, anchor: .leading)
        }
        .contentShape(Rectangle())
        .gesture(pressGesture)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(NSLocalizedString("session.menu.giveup", comment: "")))
        .accessibilityHint(Text(NSLocalizedString("session.menu.giveup.hold.a11y", comment: "")))
    }

    private var idleContent: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color(hex: 0xFF453A))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(FT.Palette.white)
                )

            Text(NSLocalizedString("session.menu.giveup", comment: ""))
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(FT.Palette.white)
        }
    }

    private var holdPill: some View {
        Text(NSLocalizedString("session.menu.giveup.hold", comment: ""))
            .font(.system(size: 17, weight: .bold))
            .foregroundStyle(FT.Palette.white)
            .blendMode(.difference)
            .padding(.horizontal, 22)
            .padding(.vertical, 11)
            .background {
                ZStack(alignment: .leading) {
                    Capsule().fill(FT.Palette.black)
                    GeometryReader { geo in
                        Rectangle()
                            .fill(FT.Palette.white)
                            .frame(width: max(0, geo.size.width * progress))
                    }
                    .clipShape(Capsule())
                }
            }
            .compositingGroup()
    }

    private var pressGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                if !isPressing {
                    startHold()
                }
            }
            .onEnded { _ in
                if isPressing && completionWorkItem != nil {
                    cancelHold()
                }
            }
    }

    private func startHold() {
        withAnimation(.easeInOut(duration: morphDuration)) {
            isPressing = true
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        scheduleTick(at: 0.5)
        scheduleTick(at: 1.0)
        scheduleTick(at: 1.5)

        let completion = DispatchWorkItem {
            guard isPressing else { return }
            commitHold()
        }
        completionWorkItem = completion
        DispatchQueue.main.asyncAfter(deadline: .now() + holdDuration, execute: completion)

        withAnimation(.linear(duration: holdDuration)) {
            progress = 1
        }
    }

    private func scheduleTick(at delay: Double) {
        let item = DispatchWorkItem {
            guard isPressing else { return }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        pendingTicks.append(item)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
    }

    private func cancelHold() {
        pendingTicks.forEach { $0.cancel() }
        pendingTicks.removeAll()
        completionWorkItem?.cancel()
        completionWorkItem = nil

        withAnimation(.easeOut(duration: rewindDuration)) {
            progress = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + rewindDuration) {
            withAnimation(.easeInOut(duration: morphDuration)) {
                isPressing = false
            }
        }
    }

    private func commitHold() {
        pendingTicks.forEach { $0.cancel() }
        pendingTicks.removeAll()
        completionWorkItem = nil
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        onCommit()
    }
}

#Preview {
    ZStack {
        FT.Palette.bgElevated.ignoresSafeArea()
        VStack(alignment: .leading) {
            GiveUpHoldRow(onCommit: { print("committed") })
                .padding(24)
            Spacer()
        }
    }
}
