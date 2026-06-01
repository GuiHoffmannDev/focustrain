import SwiftUI
import Observation
import UIKit

/// In-app "Tunnel Mode": the single source of truth the session chrome and
/// `TunnelHero` visual bind to. Today it suppresses in-app banners and flips
/// state; it is intentionally side-effect-light so a Family Controls
/// implementation can replace it without touching the UI.
@MainActor
@Observable
final class InAppTunnelController: TunnelControlling {
    private(set) var isActive: Bool = false

    func enter() {
        guard !isActive else { return }
        isActive = true
        fireHaptic(.success)
    }

    func exit() {
        guard isActive else { return }
        isActive = false
        fireHaptic(.warning)
    }

    private func fireHaptic(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
}
