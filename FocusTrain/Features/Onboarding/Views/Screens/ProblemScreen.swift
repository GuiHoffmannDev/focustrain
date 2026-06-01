import SwiftUI

struct ProblemScreen: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer()
            DisplayKeyword(
                context: NSLocalizedString("onboarding.problem.context", comment: ""),
                keyword: NSLocalizedString("onboarding.problem.keyword", comment: ""),
                keywordFont: FT.Typography.displayXL
            )
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
