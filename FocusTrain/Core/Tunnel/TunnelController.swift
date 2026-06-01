import Foundation

/// Abstraction over distraction-suppression during a ride.
/// `InAppTunnelController` is the current implementation; a future
/// `FamilyControlsTunnelController` (ManagedSettings shield) can slot in
/// behind this same protocol once the entitlement + device exist.
@MainActor
protocol TunnelControlling: AnyObject {
    var isActive: Bool { get }
    func enter()
    func exit()
}

extension TunnelControlling {
    func toggle() {
        if isActive { exit() } else { enter() }
    }
}
