import SwiftUI

struct ScenarioChips: View {
    @Binding var selection: FocusScenario

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(FocusScenario.allCases) { scenario in
                chip(for: scenario)
            }
        }
    }

    private func chip(for scenario: FocusScenario) -> some View {
        let isSelected = selection == scenario
        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                selection = scenario
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: scenario.symbol)
                    .font(.system(size: 16, weight: .semibold))
                Text(LocalizedStringKey(scenario.displayKey))
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .foregroundStyle(FT.Palette.ink)
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Capsule().fill(scenario.tint)
            )
            .overlay(
                Capsule().stroke(
                    isSelected ? FT.Palette.brandRail : Color.clear,
                    lineWidth: 3
                )
            )
            .scaleEffect(isSelected ? 1.03 : 1.0)
        }
        .buttonStyle(.plain)
    }
}
