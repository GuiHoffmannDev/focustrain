import SwiftUI
import Observation

/// In-session source of truth for the ambient-sound UI. Persists the master
/// switch and the chosen sound across launches via UserDefaults. Volume is
/// session-ephemeral by design — a per-ride convenience, not a stored
/// preference. `volume == 0` is the mute state. Phase 3 ships UI + persistence
/// only; Phase 4 will hang an AVAudioPlayer off `isPlaying` without touching
/// the views.
@MainActor
@Observable
final class AmbientSoundController {
    private enum Keys {
        static let enabled   = "ambientSoundEnabled"
        static let selection = "ambientSoundSelection"
    }

    var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: Keys.enabled) }
    }

    var selected: AmbientSound? {
        didSet {
            UserDefaults.standard.set(selected?.rawValue ?? "", forKey: Keys.selection)
        }
    }

    var volume: Double = 0.6

    var isPlaying: Bool { isEnabled && volume > 0 && selected != nil }

    init() {
        let defaults = UserDefaults.standard
        self.isEnabled = defaults.object(forKey: Keys.enabled) as? Bool ?? true
        let raw = defaults.string(forKey: Keys.selection) ?? ""
        self.selected = AmbientSound(rawValue: raw)
    }
}
