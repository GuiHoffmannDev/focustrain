import SwiftUI
import Observation
import UIKit

enum AwakePolicy: String, CaseIterable {
    case automatic
    case on
    case off

    var localizedKey: String {
        switch self {
        case .automatic: return "session.menu.awake.automatic"
        case .on:        return "session.menu.awake.on"
        case .off:       return "session.menu.awake.off"
        }
    }

    func nextInCycle() -> AwakePolicy {
        switch self {
        case .automatic: return .on
        case .on:        return .off
        case .off:       return .automatic
        }
    }
}

/// Owns the rule for whether `UIApplication.shared.isIdleTimerDisabled` is on.
/// Policy persists across sessions via `UserDefaults` (the `@AppStorage`
/// wrapper does not play nice with `@Observable`, so we read/write the key
/// directly and emit via the macro-generated observation).
@MainActor
@Observable
final class ScreenAwakeController {
    private static let storageKey = "screenAwakePolicy"

    var policy: AwakePolicy {
        didSet {
            UserDefaults.standard.set(policy.rawValue, forKey: Self.storageKey)
        }
    }

    init() {
        let raw = UserDefaults.standard.string(forKey: Self.storageKey)
        policy = AwakePolicy(rawValue: raw ?? "") ?? .automatic
    }

    func cycle() {
        policy = policy.nextInCycle()
    }

    /// Apply the current policy to the system idle timer. Call on every
    /// policy change AND on every `isPaused` flip so `.automatic` reacts.
    func apply(isPaused: Bool) {
        let shouldStayAwake: Bool
        switch policy {
        case .on:        shouldStayAwake = true
        case .off:       shouldStayAwake = false
        case .automatic: shouldStayAwake = !isPaused
        }
        UIApplication.shared.isIdleTimerDisabled = shouldStayAwake
    }
}
