import SwiftUI
import SwiftData

/// The arrival celebration: a gold/white confetti burst, a success haptic, a
/// glowing "you've arrived" hero, the completed ticket stamped, and a CTA that
/// saves the journey (SwiftData) and returns to Home. Scale/spring entrance.
struct ArrivalView: View {
    let ticket: Ticket
    /// Fired after the journey is saved (or dismissed) — clears the active
    /// session and dismisses the ride cover.
    var onDone: () -> Void

    @Environment(\.modelContext) private var context

    @State private var appeared = false
    @State private var burst = false
    @State private var saving = false

    private var scenario: FocusScenario {
        FocusScenario(rawValue: ticket.scenario) ?? .forest
    }

    var body: some View {
        ZStack {
            // Backdrop.
            FT.Palette.bgPrimary.ignoresSafeArea()
            RadialGradient(
                colors: [FT.Palette.brandBrass.opacity(0.18), .clear],
                center: .center, startRadius: 40, endRadius: 420
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer(minLength: 8)

                hero
                    .scaleEffect(appeared ? 1 : 0.8)
                    .opacity(appeared ? 1 : 0)

                ticketCard
                    .scaleEffect(appeared ? 1 : 0.88)
                    .opacity(appeared ? 1 : 0)

                Spacer(minLength: 8)

                actions
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 24)
            }
            .padding(.horizontal, FT.Layout.sideMargin)
            .padding(.vertical, 24)

            // Confetti plays above the chrome.
            if burst {
                ConfettiCanvas()
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
        }
        .onAppear(perform: celebrate)
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(FT.Palette.brandBrass.opacity(0.14))
                    .frame(width: 116, height: 116)
                    .scaleEffect(burst ? 1.06 : 0.94)
                Circle()
                    .stroke(FT.Palette.brandBrass.opacity(0.5), lineWidth: 1.5)
                    .frame(width: 92, height: 92)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(FT.Palette.brandBrass)
                    .shadow(color: FT.Palette.brandBrass.opacity(0.6), radius: 18)
            }

            GlowText(text: NSLocalizedString("arrival.title", comment: ""),
                     font: FT.Typography.heroTitle)

            Text(NSLocalizedString("arrival.subtitle", comment: ""))
                .font(FT.Typography.body)
                .foregroundStyle(FT.Palette.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Ticket

    private var ticketCard: some View {
        TrainTicketCard(
            fromCode: ticket.fromCode,
            toCode: ticket.toCode,
            fromName: ticket.fromCity,
            toName: ticket.toCity,
            scenarioTag: NSLocalizedString(scenario.displayKey, comment: ""),
            departLabel: ticket.departDate.formatted(date: .omitted, time: .shortened),
            durationLabel: "\(ticket.durationMinutes) \(NSLocalizedString("compose.duration.minutes", comment: ""))",
            ticketCode: ticket.code
        )
        .overlay(alignment: .topTrailing) {
            stamp
                .padding(.trailing, 26)
                .padding(.top, 18)
        }
    }

    /// A rotated "arrived" stamp pressed onto the ticket.
    private var stamp: some View {
        Text(NSLocalizedString("session.arrive", comment: "").uppercased())
            .font(.system(size: 13, weight: .heavy, design: .rounded))
            .tracking(1.5)
            .foregroundStyle(FT.Palette.success)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(FT.Palette.success.opacity(0.7), lineWidth: 2)
            )
            .rotationEffect(.degrees(-12))
            .scaleEffect(appeared ? 1 : 1.6)
            .opacity(appeared ? 0.9 : 0)
    }

    // MARK: - Actions

    private var actions: some View {
        VStack(spacing: 12) {
            CTAButton(
                title: NSLocalizedString("arrival.save", comment: ""),
                style: .primary,
                icon: "tray.and.arrow.down.fill",
                isLoading: saving
            ) {
                save()
            }

            CTAButton(
                title: NSLocalizedString("arrival.dismiss", comment: ""),
                style: .ghost
            ) {
                onDone()
            }
        }
    }

    // MARK: - Behaviour

    private func celebrate() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
            appeared = true
        }
        withAnimation(.easeOut(duration: 0.3)) {
            burst = true
        }
    }

    private func save() {
        guard !saving else { return }
        saving = true
        JourneyStore.save(ticket, in: context)
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        onDone()
    }
}
