import SwiftUI

/// A large monospaced "MM:SS" countdown that animates digit changes via
/// `contentTransition(.numericText())`, matching onboarding's numeric polish.
struct CountdownLabel: View {
    /// Pre-formatted "MM:SS" string.
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 64, weight: .bold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(FT.Palette.textPrimary)
            .contentTransition(.numericText())
            .shadow(color: FT.Palette.brandRail.opacity(0.35), radius: 18)
    }
}
