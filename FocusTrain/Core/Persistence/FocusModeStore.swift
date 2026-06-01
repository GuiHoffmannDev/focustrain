import SwiftUI
import Observation

/// Owns the user's library of custom focus-mode presets — built via the "+"
/// chip in `SeatPickerView`. Persists as a JSON array in UserDefaults so
/// presets survive app relaunches.
@MainActor
@Observable
final class FocusModeStore {
    private static let storageKey = "customFocusModes"

    private(set) var customModes: [CustomFocusMode] = [] {
        didSet { persist() }
    }

    init() {
        load()
    }

    func add(_ mode: CustomFocusMode) {
        customModes.append(mode)
    }

    func remove(_ mode: CustomFocusMode) {
        customModes.removeAll { $0.id == mode.id }
    }

    // MARK: - Persistence

    private func load() {
        guard
            let raw = UserDefaults.standard.string(forKey: Self.storageKey),
            let data = raw.data(using: .utf8),
            let modes = try? JSONDecoder.ft.decode([CustomFocusMode].self, from: data)
        else { return }
        customModes = modes
    }

    private func persist() {
        let defaults = UserDefaults.standard
        guard
            let data = try? JSONEncoder.ft.encode(customModes),
            let raw = String(data: data, encoding: .utf8)
        else {
            defaults.removeObject(forKey: Self.storageKey)
            return
        }
        defaults.set(raw, forKey: Self.storageKey)
    }
}