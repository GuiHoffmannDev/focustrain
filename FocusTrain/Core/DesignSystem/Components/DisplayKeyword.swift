import SwiftUI

struct DisplayKeyword: View {
    let context: String
    let keyword: String
    var keywordColor: Color = FT.Palette.brandRail
    var keywordFont: Font = FT.Typography.displayL
    var alignment: HorizontalAlignment = .leading

    var body: some View {
        VStack(alignment: alignment, spacing: 12) {
            Text(context)
                .font(FT.Typography.contextLine)
                .foregroundStyle(FT.Palette.textSecondary)
                .multilineTextAlignment(textAlignment)

            Text(keyword)
                .font(keywordFont)
                .foregroundStyle(keywordColor)
                .multilineTextAlignment(textAlignment)
                .lineLimit(3)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: frameAlignment)
    }

    private var textAlignment: TextAlignment {
        switch alignment {
        case .leading:  return .leading
        case .trailing: return .trailing
        default:        return .center
        }
    }

    private var frameAlignment: Alignment {
        switch alignment {
        case .leading:  return .leading
        case .trailing: return .trailing
        default:        return .center
        }
    }
}
