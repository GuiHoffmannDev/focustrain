import SwiftUI
import Observation
import Intents

/// Tracks whether the SessionView "Airplane Mode" toggle is on. iOS does not
/// let third-party apps flip the system Focus status directly — that path
/// runs through Shortcuts donations / Focus filters. For now we maintain
/// local state (persisted) and request Focus authorization so the system
/// recognises our interest; real iOS Focus integration is a follow-up.
@MainActor
@Observable
final class FocusModeController {
    private static let storageKey = "focusModeOn"

    var isOn: Bool {
        didSet {
            UserDefaults.standard.set(isOn, forKey: Self.storageKey)
        }
    }

    init() {
        isOn = UserDefaults.standard.bool(forKey: Self.storageKey)
    }

    func toggle() async {
        let status = INFocusStatusCenter.default.authorizationStatus
        if status == .notDetermined {
            _ = await INFocusStatusCenter.default.requestAuthorization()
        }
        isOn.toggle()
    }
}
