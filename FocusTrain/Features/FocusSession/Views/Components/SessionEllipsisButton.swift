import SwiftUI

/// Top-right pause-state button. Shows three dots when the menu is closed and
/// flips to an X while the menu is open, so re-tapping clearly dismisses.
struct SessionEllipsisButton: View {
    @Binding var isMenuOpen: Bool

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            isMenuOpen.toggle()
        } label: {
            Image(systemName: isMenuOpen ? "xmark" : "ellipsis")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(FT.Palette.textPrimary)
                .frame(width: 48, height: 48)
                .background {
                    Color.clear.ftGlassCircle(interactive: true, liquid: true)
                }
                .contentShape(Circle())
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(NSLocalizedString("session.menu.more.a11y", comment: "Open the pause menu")))
    }
}

#Preview {
    ZStack {
        FT.Palette.bgElevated.ignoresSafeArea()
        SessionEllipsisButton(isMenuOpen: .constant(false))
    }
}
