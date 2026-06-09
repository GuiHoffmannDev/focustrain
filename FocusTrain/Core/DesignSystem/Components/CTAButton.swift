import SwiftUI
import UIKit

struct CTAButton: View {
    enum Style { case primary, secondary, ghost }

    let title: String
    var style: Style = .primary
    var icon: String? = nil
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: {
            guard !isLoading else { return }
            action()
        }) {
            ZStack {
                HStack(spacing: 8) {
                    Text(title).font(FT.Typography.button)
                    if let icon { Image(systemName: icon) }
                }
                .opacity(isLoading ? 0 : 1)

                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(foreground)
                }
            }
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .frame(height: FT.Layout.ctaHeight)
            .overlay {
                if style == .ghost {
                    Capsule().stroke(FT.Palette.textMuted.opacity(0.32), lineWidth: 1)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isLoading)
        }
        .buttonStyle(FTGlassButtonStyle(shape: .capsule, tint: style == .primary ? FT.Palette.brandRail : nil))
        .disabled(isLoading)
    }

    private var foreground: Color {
        switch style {
        case .primary:   return FT.Palette.ink
        case .secondary: return FT.Palette.white
        case .ghost:     return FT.Palette.white
        }
    }
}

struct FTGlassIconButton: View {
    let systemName: String
    var size: CGFloat = 40
    var iconSize: CGFloat = 14
    var foreground: Color = FT.Palette.white
    var tint: Color? = nil
    var accessibilityLabel: LocalizedStringKey? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: iconSize, weight: .bold))
                .foregroundStyle(foreground)
                .frame(width: size, height: size)
                .background {
                    Circle()
                        .fill(.clear)
                        .ftGlassCircle(interactive: true, tint: tint, liquid: true)
                }
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel.map { Text($0) } ?? Text(systemName))
    }
}

extension View {
    func ftGlassCapsule(interactive: Bool = false, tint: Color? = nil, liquid: Bool = false) -> some View {
        ftGlass(.capsule, interactive: interactive, tint: tint, liquid: liquid)
    }
    func ftGlassCircle(interactive: Bool = false, tint: Color? = nil, liquid: Bool = false) -> some View {
        ftGlass(.circle, interactive: interactive, tint: tint, liquid: liquid)
    }
    func ftGlassRounded(cornerRadius: CGFloat, interactive: Bool = false, tint: Color? = nil, liquid: Bool = false) -> some View {
        ftGlass(.rounded(cornerRadius), interactive: interactive, tint: tint, liquid: liquid)
    }
}
