import Foundation
import CoreGraphics
#if os(iOS)
import UIKit
import CoreHaptics
#endif

protocol TearHapticsService: AnyObject {
    func prepare()
    func startTear()
    func updateTear(progress: CGFloat, velocity: CGFloat)
    func completeTear()
    func cancelTear()
}

enum TearHaptics {
    static func make() -> TearHapticsService {
        #if os(iOS)
        if !ProcessInfo.processInfo.isiOSAppOnMac,
           CHHapticEngine.capabilitiesForHardware().supportsHaptics {
            return CoreHapticsTearService()
        }
        return ImpactFallbackTearService()
        #else
        return NoopTearService()
        #endif
    }
}

final class NoopTearService: TearHapticsService {
    func prepare() {}
    func startTear() {}
    func updateTear(progress: CGFloat, velocity: CGFloat) {}
    func completeTear() {}
    func cancelTear() {}
}

#if os(iOS)

/// Continuous Core Haptics pattern, intensity modulated by velocity and
/// sharpness by progress, to feel like paper tearing under the finger.
final class CoreHapticsTearService: TearHapticsService {
    private var engine: CHHapticEngine?
    private var continuousPlayer: CHHapticAdvancedPatternPlayer?

    func prepare() {
        guard engine == nil else { return }
        do {
            let e = try CHHapticEngine()
            e.isAutoShutdownEnabled = true
            e.stoppedHandler = { [weak self] _ in self?.engine = nil }
            e.resetHandler = { [weak self] in
                try? self?.engine?.start()
                self?.continuousPlayer = nil
            }
            try e.start()
            engine = e
        } catch {
            engine = nil
        }
    }

    func startTear() {
        guard let engine else { return }
        do {
            let pattern = try CHHapticPattern(events: [
                CHHapticEvent(
                    eventType: .hapticContinuous,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
                    ],
                    relativeTime: 0,
                    duration: 30
                )
            ], parameters: [])
            let player = try engine.makeAdvancedPlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
            continuousPlayer = player
        } catch {
            continuousPlayer = nil
        }
    }

    func updateTear(progress: CGFloat, velocity: CGFloat) {
        guard let player = continuousPlayer else { return }
        let v = min(max(Float(abs(velocity) / 1500), 0), 1)
        let p = min(max(Float(progress), 0), 1)
        let intensity = 0.4 + v * 0.5
        let sharpness = 0.3 + p * 0.5
        let params = [
            CHHapticDynamicParameter(parameterID: .hapticIntensityControl, value: intensity, relativeTime: 0),
            CHHapticDynamicParameter(parameterID: .hapticSharpnessControl, value: sharpness, relativeTime: 0)
        ]
        try? player.sendParameters(params, atTime: CHHapticTimeImmediate)
    }

    func completeTear() {
        try? continuousPlayer?.stop(atTime: CHHapticTimeImmediate)
        continuousPlayer = nil
        guard let engine else { return }
        do {
            let pattern = try CHHapticPattern(events: [
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
                    ],
                    relativeTime: 0
                )
            ], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {}
    }

    func cancelTear() {
        try? continuousPlayer?.stop(atTime: CHHapticTimeImmediate)
        continuousPlayer = nil
    }
}

/// Step-based fallback: a soft impact every ~5% progress for devices
/// without Core Haptics support.
final class ImpactFallbackTearService: TearHapticsService {
    private let gen = UIImpactFeedbackGenerator(style: .soft)
    private var lastStep: Int = -1

    func prepare() { gen.prepare() }
    func startTear() { lastStep = -1; gen.prepare() }

    func updateTear(progress: CGFloat, velocity: CGFloat) {
        let step = Int(progress * 20)
        if step != lastStep {
            lastStep = step
            gen.impactOccurred(intensity: 0.6)
        }
    }

    func completeTear() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    func cancelTear() { lastStep = -1 }
}

#endif
