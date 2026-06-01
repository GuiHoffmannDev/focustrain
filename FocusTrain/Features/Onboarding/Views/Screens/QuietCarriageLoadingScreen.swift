import SwiftUI

struct QuietCarriageLoadingScreen: View {
    @State private var pulse = false

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer().frame(height: 8)

            DisplayKeyword(
                context: NSLocalizedString("onboarding.quietLoading.context", comment: ""),
                keyword: NSLocalizedString("onboarding.quietLoading.keyword", comment: ""),
                keywordFont: FT.Typography.displayL
            )

            Text(NSLocalizedString("onboarding.quietLoading.subtitle", comment: ""))
                .font(FT.Typography.body)
                .foregroundStyle(FT.Palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            HStack {
                Spacer()
                ZStack {
                    Circle()
                        .stroke(FT.Palette.textMuted.opacity(0.2), lineWidth: 4)
                        .frame(width: 96, height: 96)
                    Circle()
                        .trim(from: 0, to: 0.3)
                        .stroke(FT.Palette.brandRail, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 96, height: 96)
                        .rotationEffect(.degrees(pulse ? 360 : 0))
                        .animation(.linear(duration: 1.2).repeatForever(autoreverses: false), value: pulse)
                    Image(systemName: "bell.slash.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(FT.Palette.brandRail)
                }
                Spacer()
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear { pulse = true }
    }
}
