import SwiftUI

/// Top-right capsule on the Home hero advertising a Premium offer with a live
/// countdown. Purely visual — the timer is local state, not real entitlement.
struct PremiumDiscountPill: View {
    /// Remaining seconds. Defaults to 60 minutes for the visual mock.
    @State private var remaining: TimeInterval

    init(remaining: TimeInterval = 60 * 60) {
        _remaining = State(initialValue: remaining)
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "tram.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(FT.Palette.brandBrass)

            Text(NSLocalizedString("home.premium.pill", comment: ""))
                .font(.system(size: 12, weight: .heavy))
                .tracking(0.5)
                .foregroundStyle(FT.Palette.textPrimary)

            Text(formatted(remaining))
                .font(.system(size: 12, weight: .heavy, design: .monospaced))
                .foregroundStyle(FT.Palette.brandBrass)
                .contentTransition(.numericText())
                .animation(.linear, value: remaining)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
        )
        .overlay(
            Capsule().stroke(FT.Palette.brandBrass.opacity(0.35), lineWidth: 1)
        )
        .task { await tick() }
    }

    private func tick() async {
        while remaining > 0 {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            if remaining > 0 { remaining -= 1 }
        }
    }

    private func formatted(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds))
        let m = total / 60
        let s = total % 60
        return String(format: "%02d:%02d", m, s)
    }
}
