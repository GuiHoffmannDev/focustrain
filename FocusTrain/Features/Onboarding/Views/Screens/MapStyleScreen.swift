import SwiftUI

struct MapStyleScreen: View {
    let highlightStyle: MapStyle
    @Binding var selection: MapStyle
    @Binding var showLabels: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer().frame(height: 8)

            DisplayKeyword(
                context: NSLocalizedString("onboarding.mapStyle.context", comment: ""),
                keyword: highlightStyle.displayName,
                keywordFont: FT.Typography.displayL
            )

            Text(NSLocalizedString("onboarding.mapStyle.subtitle", comment: ""))
                .font(FT.Typography.body)
                .foregroundStyle(FT.Palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            MapStyleSelector(selection: $selection, showLabels: $showLabels)

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            if selection != highlightStyle {
                selection = highlightStyle
            }
        }
    }
}
