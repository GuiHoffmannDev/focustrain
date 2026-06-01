import SwiftUI

struct SolutionScreen: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer()
            DisplayKeyword(
                context: NSLocalizedString("onboarding.solution.context", comment: ""),
                keyword: NSLocalizedString("onboarding.solution.keyword", comment: ""),
                keywordFont: FT.Typography.displayXL
            )
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
