import Foundation
#if os(iOS)
import UIKit
import CoreHaptics
#endif

/// A single crisp "tick" per detent crossed (ruler mark / selection change).
protocol DetentHapticsService: AnyObject {
    func prepare()
    func tick()
    func fineTick()
}

enum DetentHaptics {
    static func make() -> DetentHapticsService {
        #if os(iOS)
        if !ProcessInfo.processInfo.isiOSAppOnMac,
           CHHapticEngine.capabilitiesForHardware().supportsHaptics {
            return CoreHapticsDetentService()
        }
        return ImpactDetentService()
        #else
        return NoopDetentService()
        #endif
    }
}

final class NoopDetentService: DetentHapticsService {
    func prepare() {}
    func tick() {}
    func fineTick() {}
}

#if os(iOS)
/// Crisp transient tick via Core Haptics.
final class CoreHapticsDetentService: DetentHapticsService {
    private var engine: CHHapticEngine?

    func prepare() {
        guard engine == nil else { return }
        do {
            let e = try CHHapticEngine()
            e.isAutoShutdownEnabled = true
            e.stoppedHandler = { [weak self] _ in self?.engine = nil }
            e.resetHandler = { [weak self] in try? self?.engine?.start() }
            try e.start()
            engine = e
        } catch { engine = nil }
    }

    func tick() {
        play(intensity: 0.7, sharpness: 0.9)
    }

    func fineTick() {
        play(intensity: 0.25, sharpness: 0.6)
    }

    private func play(intensity: Float, sharpness: Float) {
        guard let engine else { return }
        do {
            let event = CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
            ], relativeTime: 0)
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {}
    }
}

/// Fallback for devices without Core Haptics.
final class ImpactDetentService: DetentHapticsService {
    private let gen = UIImpactFeedbackGenerator(style: .rigid)
    private let fineGen = UIImpactFeedbackGenerator(style: .light)
    func prepare() { gen.prepare(); fineGen.prepare() }
    func tick() { gen.impactOccurred(intensity: 0.85); gen.prepare() }
    func fineTick() { fineGen.impactOccurred(intensity: 0.35); fineGen.prepare() }
}
#endif
