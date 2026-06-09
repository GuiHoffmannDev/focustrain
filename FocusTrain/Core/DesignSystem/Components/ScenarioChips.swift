import SwiftUI

struct ScenarioChips: View {
    @Binding var selection: FocusScenario

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        FTGlassContainer {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(FocusScenario.allCases) { scenario in
                    chip(for: scenario)
                }
            }
        }
    }

    private func chip(for scenario: FocusScenario) -> some View {
        FTGlassChip(
            isSelected: selection == scenario,
            tint: scenario.tint,
            action: { selection = scenario }
        ) {
            HStack(spacing: 10) {
                Image(systemName: scenario.symbol)
                    .font(.system(size: 16, weight: .semibold))
                Text(LocalizedStringKey(scenario.displayKey))
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
