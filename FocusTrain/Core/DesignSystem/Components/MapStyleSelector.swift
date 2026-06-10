import SwiftUI

enum MapStyle: String, CaseIterable, Identifiable {
    case monochrome, terra, standard, satellite

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .monochrome: return "Monocromático"
        case .terra:      return "Terra"
        case .standard:   return "Padrão"
        case .satellite:  return "Satélite"
        }
    }

    var swatch: [Color] {
        switch self {
        case .monochrome: return [Color(light: 0xEEEEEE, dark: 0x222222),
                                  Color(light: 0xBBBBBB, dark: 0x555555)]
        case .terra:      return [Color(hex: 0x8B6F4E), Color(hex: 0xC09872)]
        case .standard:   return [Color(hex: 0x2E5C8A), Color(hex: 0x4F86C6)]
        case .satellite:  return [Color(hex: 0x1B3A2E), Color(hex: 0x3D7053)]
        }
    }
}

struct MapStyleSelector: View {
    @Binding var selection: MapStyle
    @Binding var showLabels: Bool

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(spacing: 16) {
            FTGlassContainer {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(MapStyle.allCases) { style in
                        tile(for: style)
                    }
                }
            }
            labelsToggle
        }
    }

    /// On the mono swatch the gradient flips light/dark, so the icon must too;
    /// the coloured swatches stay dark-ish in both schemes, so white reads there.
    private func mapIconColor(for style: MapStyle) -> Color {
        style == .monochrome
            ? Color(light: 0x1A1A1A, dark: 0xFFFFFF).opacity(0.4)
            : FT.Palette.white.opacity(0.4)
    }

    private func tile(for style: MapStyle) -> some View {
        let isSelected = selection == style
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selection = style
            }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: style.swatch,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 80)
                    .overlay(
                        Image(systemName: "map")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(mapIconColor(for: style))
                    )
                Text(style.displayName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(FT.Palette.textPrimary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(EmptyView())
            .ftGlass(.rounded(18), interactive: true, tint: isSelected ? FT.Palette.brandRail.opacity(0.28) : nil)
            .ftGlassSelectionStroke(isSelected: isSelected, shape: .rounded(18))
        }
        .buttonStyle(.plain)
    }

    private var labelsToggle: some View {
        HStack {
            Text("Mostrar rótulos")
                .font(FT.Typography.body)
                .foregroundStyle(FT.Palette.textPrimary)
            Spacer()
            Toggle("", isOn: $showLabels)
                .labelsHidden()
                .tint(FT.Palette.brandRail)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.clear)
                .ftGlassRounded(cornerRadius: 18)
        )
    }
}
