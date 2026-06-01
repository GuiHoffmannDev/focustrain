import SwiftUI

@MainActor
@Observable
final class OnboardingViewModel {
    var current: OnboardingStep = .welcome
    var selectedScenario: FocusScenario = .forest
    var quietCarriageEnabled: Bool = false
    var selectedMapStyle: MapStyle = .monochrome
    var showLabels: Bool = true
    var isLoading: Bool = false

    var progress: Double {
        Double(current.rawValue + 1) / Double(OnboardingStep.total)
    }

    func next() {
        if current == .quietCarriageLoading {
            advanceWithLoadingDelay()
            return
        }
        advance()
    }

    func back() {
        guard let prv = OnboardingStep(rawValue: current.rawValue - 1) else { return }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
            current = prv
        }
    }

    func skipToReady() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
            current = .readyFinal
        }
    }

    func finish() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        UserDefaults.standard.set(selectedScenario.rawValue, forKey: "defaultScenario")
        UserDefaults.standard.set(quietCarriageEnabled, forKey: "quietCarriageEnabled")
        UserDefaults.standard.set(selectedMapStyle.rawValue, forKey: "defaultMapStyle")
        UserDefaults.standard.set(showLabels, forKey: "mapShowLabels")
    }

    private func advance() {
        guard let nxt = OnboardingStep(rawValue: current.rawValue + 1) else {
            finish()
            return
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
            current = nxt
        }
    }

    private func advanceWithLoadingDelay() {
        isLoading = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            isLoading = false
            advance()
        }
    }
}
