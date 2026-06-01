import SwiftUI

struct ScenarioPickerScreen: View {
    @Binding var selection: FocusScenario

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer().frame(height: 8)

            DisplayKeyword(
                context: NSLocalizedString("onboarding.scenario.context", comment: ""),
                keyword: NSLocalizedString("onboarding.scenario.keyword", comment: ""),
                keywordFont: FT.Typography.displayL
            )

            ScenarioChips(selection: $selection)

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
