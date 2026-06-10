import SwiftUI

/// Full-screen takeover that floats over the map while the SessionView is
/// paused and the user taps the 3-dots button. Items stack at top-leading,
/// the rest of the chrome is faded by the parent.
struct SessionPauseMenu: View {
    var awakePolicy: AwakePolicy
    var focusOn: Bool
    var onGiveUp: () -> Void
    var onAirplaneTap: () -> Void
    var onAwakeTap: () -> Void
    var onDismiss: () -> Void

    @State private var itemsVisible: [Bool] = [false, false, false]

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Backdrop: tap anywhere to dismiss.
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            FT.Palette.scrim.opacity(0.45)
                .ignoresSafeArea()

            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { onDismiss() }
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                item(index: 0) {
                    GiveUpHoldRow(onCommit: onGiveUp)
                }

                item(index: 1) {
                    MenuItemRow(
                        iconName: "airplane",
                        iconBackground: FT.Palette.gray800.opacity(0.85),
                        title: NSLocalizedString("session.menu.airplane", comment: ""),
                        subtitle: .counters,
                        action: onAirplaneTap
                    )
                }

                item(index: 2) {
                    MenuItemRow(
                        iconName: "sun.max.fill",
                        iconBackground: FT.Palette.indigo,
                        title: NSLocalizedString("session.menu.awake", comment: ""),
                        subtitle: .picker(NSLocalizedString(awakePolicy.localizedKey, comment: "")),
                        action: onAwakeTap
                    )
                }
            }
            .padding(.top, 120)
            .frame(maxWidth: .infinity)
        }
        .onAppear { staggerIn() }
    }

    @ViewBuilder
    private func item<Content: View>(index: Int, @ViewBuilder content: () -> Content) -> some View {
        content()
            .opacity(itemsVisible[index] ? 1 : 0)
            .offset(y: itemsVisible[index] ? 0 : -16)
    }

    private func staggerIn() {
        for (i, delay) in [0.0, 0.05, 0.10].enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeOut(duration: 0.25)) {
                    itemsVisible[i] = true
                }
            }
        }
    }
}

// MARK: - Row

private enum MenuItemSubtitle {
    case none
    case counters
    case picker(String)
}

private struct MenuItemRow: View {
    let iconName: String
    let iconBackground: Color
    let title: String
    let subtitle: MenuItemSubtitle
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Circle()
                    .fill(iconBackground)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: iconName)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(FT.Palette.textPrimary)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(FT.Palette.textPrimary)

                    subtitleView
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var subtitleView: some View {
        switch subtitle {
        case .none:
            EmptyView()
        case .counters:
            HStack(spacing: 8) {
                counter(icon: "iphone")
                divider
                counter(icon: "square.stack.3d.up")
                divider
                counter(icon: "safari")
            }
            .foregroundStyle(FT.Palette.textSecondary)
        case .picker(let label):
            HStack(spacing: 6) {
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(FT.Palette.textSecondary)
        }
    }

    private func counter(icon: String) -> some View {
        HStack(spacing: 4) {
            Text("0")
                .font(.system(size: 13, weight: .semibold))
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(FT.Palette.textMuted.opacity(0.5))
            .frame(width: 1, height: 12)
    }
}

#Preview {
    ZStack {
        FT.Palette.bgElevated.ignoresSafeArea()
        SessionPauseMenu(
            awakePolicy: .automatic,
            focusOn: false,
            onGiveUp: {},
            onAirplaneTap: {},
            onAwakeTap: {},
            onDismiss: {}
        )
    }
}
