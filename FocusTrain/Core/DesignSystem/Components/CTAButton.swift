import SwiftUI
import UIKit

struct CTAButton: View {
    enum Style { case primary, secondary, ghost }

    let title: String
    var style: Style = .primary
    var icon: String? = nil
    var isLoading: Bool = false
    let action: () -> Void

    @State private var pressed = false

    var body: some View {
        Button(action: {
            guard !isLoading else { return }
            let gen = UIImpactFeedbackGenerator(style: .medium)
            gen.impactOccurred()
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
            .background(background)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(borderColor, lineWidth: style == .ghost ? 1 : 0)
            )
            .scaleEffect(pressed && !isLoading ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: pressed)
            .animation(.easeInOut(duration: 0.2), value: isLoading)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressed = true }
                .onEnded { _ in pressed = false }
        )
    }

    private var foreground: Color {
        switch style {
        case .primary:   return FT.Palette.ink
        case .secondary: return FT.Palette.white
        case .ghost:     return FT.Palette.white
        }
    }
    private var background: Color {
        switch style {
        case .primary:   return FT.Palette.brandRail
        case .secondary: return FT.Palette.bgElevated
        case .ghost:     return Color.clear
        }
    }
    private var borderColor: Color {
        style == .ghost ? FT.Palette.textMuted.opacity(0.4) : .clear
    }
}
