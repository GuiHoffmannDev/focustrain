import SwiftUI

struct QuietCarriageScreen: View {
    @Binding var enabled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            Spacer().frame(height: 8)

            DisplayKeyword(
                context: NSLocalizedString("onboarding.quietCarriage.context", comment: ""),
                keyword: NSLocalizedString("onboarding.quietCarriage.keyword", comment: ""),
                keywordFont: FT.Typography.displayL
            )

            Text(NSLocalizedString("onboarding.quietCarriage.subtitle", comment: ""))
                .font(FT.Typography.body)
                .foregroundStyle(FT.Palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            toggleCard

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var toggleCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(FT.Palette.brandRail.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: "bell.slash.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(FT.Palette.brandRail)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(NSLocalizedString("onboarding.quietCarriage.toggle.title", comment: ""))
                    .font(FT.Typography.button)
                    .foregroundStyle(FT.Palette.textPrimary)
                Text(NSLocalizedString("onboarding.quietCarriage.toggle.caption", comment: ""))
                    .font(FT.Typography.caption)
                    .foregroundStyle(FT.Palette.textSecondary)
            }
            Spacer()
            Toggle("", isOn: $enabled)
                .labelsHidden()
                .tint(FT.Palette.brandRail)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(FT.Palette.bgElevated)
        )
    }
}
