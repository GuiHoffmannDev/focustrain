import SwiftUI
#if os(iOS)
import UIKit
#endif

/// Boarding pass ritual screen — prints the ticket on appearance, then
/// requires a left→right tear over the perforation to start the session.
///
/// Public entry point of the feature. Plug into the SeatPicker via a
/// `.fullScreenCover` and route `onTearComplete` to the existing
/// session-start path.
struct BoardingPassView: View {
    let ticket: Ticket
    var onTearComplete: (Ticket) -> Void
    var onCancel: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("ft.sound.departure") private var soundOnDeparture: Bool = true

    @State private var printingDone = false

    private var display: BoardingPassDisplay { BoardingPassDisplay(ticket) }
    private let ticketWidth: CGFloat = 360
    private let ticketHeight: CGFloat = 470
    private let slotHeight: CGFloat = 26

    var body: some View {
        ZStack {
            FT.Palette.bgPrimary.ignoresSafeArea()
            backdropGlow

            VStack(spacing: 0) {
                Spacer(minLength: 24)

                VStack(spacing: -2) {
                    // Printer slot — fades out once the ticket is fully out,
                    // so the boarding pass stands on its own for the tear.
                    if !printingDone {
                        PrinterSlotView(width: ticketWidth)
                            .zIndex(2)
                            .transition(.asymmetric(
                                insertion: .opacity,
                                removal: .opacity.combined(with: .move(edge: .top))
                            ))
                    } else {
                        // Reserve the same vertical space so the ticket
                        // doesn't jump up when the slot disappears.
                        Color.clear
                            .frame(height: 26)
                    }

                    // Ticket — clipped to its frame so the part still
                    // "inside" the printer (slid above its top) stays
                    // hidden behind the slot.
                    ticketCard
                        .frame(width: ticketWidth)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(Text(display.accessibilitySummary))
                        .accessibilityAddTraits(.isSummaryElement)
                }
                .padding(.horizontal, FT.Layout.sideMargin)
                .animation(.easeOut(duration: 0.4), value: printingDone)

                if printingDone {
                    if reduceMotion {
                        checkInButton
                            .padding(.horizontal, FT.Layout.sideMargin)
                            .padding(.top, 24)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    } else {
                        tearCTA
                            .padding(.horizontal, FT.Layout.sideMargin)
                            .padding(.top, 24)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }

                Spacer(minLength: 24)
            }

            closeButton
        }
        .accessibilityAction(named: Text("Check in"), confirm)
    }

    // MARK: - Layers

    private var backdropGlow: some View {
        RadialGradient(
            colors: [FT.Palette.brandRail.opacity(0.08), .clear],
            center: .center,
            startRadius: 0,
            endRadius: 360
        )
        .ignoresSafeArea()
    }

    private var ticketCard: some View {
        TearableTicketView(
            display: display,
            interactive: printingDone && !reduceMotion,
            onTearComplete: confirm,
            onCancel: {}
        )
        .printingReveal(
            enabled: !reduceMotion,
            height: ticketHeight,
            duration: 1.6,
            soundEnabled: soundOnDeparture,
            onComplete: {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.85)) {
                    printingDone = true
                }
            }
        )
    }

    private var tearCTA: some View {
        VStack(spacing: 6) {
            Text("Seu embarque está pronto")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(FT.Palette.textPrimary)
            HStack(spacing: 8) {
                Image(systemName: "hand.draw.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(FT.Palette.brandRail.opacity(0.7))
                Text("Rasgue a perfuração para começar")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(FT.Palette.textPrimary.opacity(0.65))
                TearArrowHint()
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityHint(Text("Arraste da esquerda para a direita sobre a perfuração"))
    }

    private var checkInButton: some View {
        CTAButton(
            title: "Check in",
            style: .primary,
            icon: "arrow.right",
            action: confirm
        )
        .accessibilityHint(Text("Confirma o embarque e inicia a sessão de foco"))
    }

    private var closeButton: some View {
        VStack {
            HStack {
                Spacer()
                FTGlassIconButton(
                    systemName: "xmark",
                    size: 36,
                    iconSize: 14,
                    foreground: FT.Palette.textPrimary.opacity(0.7),
                    accessibilityLabel: "Cancelar"
                ) {
                    onCancel()
                }
                .padding(.trailing, FT.Layout.sideMargin)
                .padding(.top, 12)
            }
            Spacer()
        }
        .accessibilityLabel(Text("Cancelar"))
    }

    // MARK: - Actions

    private func confirm() {
        #if os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
        onTearComplete(ticket)
    }
}

/// Small chevron that nudges left→right repeatedly to suggest the tear gesture.
private struct TearArrowHint: View {
    @State private var animate = false

    var body: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(FT.Palette.brandRail.opacity(0.75))
            .offset(x: animate ? 4 : 0)
            .opacity(animate ? 0.4 : 1)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                    animate = true
                }
            }
    }
}

#if DEBUG
#Preview {
    BoardingPassView(
        ticket: Ticket(
            scenario: "forest",
            fromCode: "CVM",
            fromCity: "Ciudad Victoria",
            toCode: "YCG",
            toCity: "Castlegar",
            fromLat: 23.7, fromLon: -99.13,
            toLat: 49.29, toLon: -117.63,
            departDate: Date().addingTimeInterval(60 * 30),
            durationMinutes: 260,
            mapStyle: "monochrome",
            code: "FT-7K2Q",
            seatCode: "01A",
            focusMode: nil
        ),
        onTearComplete: { _ in },
        onCancel: {}
    )
}
#endif
