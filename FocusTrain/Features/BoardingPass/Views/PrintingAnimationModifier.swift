import SwiftUI
#if os(iOS)
import UIKit
#endif

/// Slides its content downward out of an implicit "printer" above, clipped to
/// a fixed `height` so anything still inside the slot stays hidden.
///
/// Compose it under a `PrinterSlotView` so the content visibly emerges from
/// behind the slot's slit. The motion uses a soft paper-feed easing and is
/// accompanied by a handful of gentle haptic taps and (optionally) the
/// printer loop sound.
struct PrintingAnimationModifier: ViewModifier {
    let height: CGFloat
    let duration: Double
    let onComplete: () -> Void
    let soundEnabled: Bool

    /// 0 = fully tucked above (invisible); 1 = fully emerged.
    @State private var progress: CGFloat = 0
    @State private var started = false
    @State private var sound: PrinterSoundPlayer?

    func body(content: Content) -> some View {
        content
            .frame(height: height)
            .offset(y: -height * (1 - progress))
            .frame(height: height, alignment: .top)
            .clipped()
            .onAppear {
                guard !started else { return }
                started = true
                runAnimation()
            }
    }

    private func runAnimation() {
        if soundEnabled {
            sound = PrinterSoundPlayer()
            sound?.start()
        }

        // Soft paper feed: brisk early, gently settling at the end.
        withAnimation(.timingCurve(0.22, 0.85, 0.32, 1.0, duration: duration)) {
            progress = 1
        }

        #if os(iOS)
        let beats: [Double] = [0.12, 0.5, 0.88]
        for b in beats {
            DispatchQueue.main.asyncAfter(deadline: .now() + duration * b) {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.3)
            }
        }
        #endif

        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.05) {
            sound?.stop()
            onComplete()
        }
    }
}

extension View {
    /// Plays the soft paper-feed reveal once on appearance, sliding content
    /// downward out of the slot above. Pass `enabled = false` to skip.
    @ViewBuilder
    func printingReveal(
        enabled: Bool,
        height: CGFloat,
        duration: Double = 1.6,
        soundEnabled: Bool,
        onComplete: @escaping () -> Void
    ) -> some View {
        if enabled {
            modifier(PrintingAnimationModifier(
                height: height,
                duration: duration,
                onComplete: onComplete,
                soundEnabled: soundEnabled
            ))
        } else {
            frame(height: height).onAppear(perform: onComplete)
        }
    }
}
