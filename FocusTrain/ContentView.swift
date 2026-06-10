import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                RootView()
            } else {
                OnboardingContainerView()
            }
        }
    }
}

/// Post-onboarding navigation shell. Owns the Home stack and presents the
/// immersive ride (Session/Arrival) as a full-screen cover, including resume
/// after a relaunch when `SessionStore` still holds an active ticket.
struct RootView: View {
    enum Route: Hashable { case compose, seatPicker(Ticket) }

    @Environment(SessionStore.self) private var session

    @State private var path = NavigationPath()
    @State private var showRide = false
    @State private var showHistory = false
    @State private var showTrends = false
    @State private var showSettings = false

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(
                onStart: { path.append(Route.compose) },
                onHistory: { showHistory = true },
                onTrends: { showTrends = true },
                onSettings: { showSettings = true }
            )
            .navigationBarBackButtonHidden(true)
            .navigationDestination(for: Route.self) { route in
                destination(for: route)
            }
        }
        .tint(FT.Palette.brandRail)
        .sheet(isPresented: $showHistory) {
            HistoryView(onClose: { showHistory = false })
                .presentationDetents([.fraction(0.7), .large])
                .presentationBackground(.ultraThinMaterial)
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showTrends) {
            TrendsSheet(onClose: { showTrends = false })
                .presentationDetents([.fraction(0.7), .large])
                .presentationBackground(.ultraThinMaterial)
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheet(onClose: { showSettings = false })
                .presentationDetents([.fraction(0.7), .large])
                .presentationBackground(.ultraThinMaterial)
                .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $showRide) {
            if let ticket = session.activeTicket {
                RidePresenter(ticket: ticket)
            }
        }
        .onAppear { syncRide() }
        .onChange(of: session.activeTicket) { _, _ in syncRide() }
    }

    private func syncRide() {
        showRide = session.phase != .idle
    }

    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case .compose:
            DurationPickerView(
                onDepart: { ticket in
                    path.append(Route.seatPicker(ticket))
                },
                onBack: { path.removeLast() }
            )
        case .seatPicker(let pendingTicket):
            SeatPickerView(
                incomingTicket: pendingTicket,
                onDepart: { finalTicket in
                    session.start(finalTicket)
                    path = NavigationPath()   // pop to Home; ride cover presents over it
                },
                onBack: { path.removeLast() }
            )
        }
    }
}

/// Placeholder sheet used by Trends and Settings until their real screens land.
private struct ComingSoonSheet: View {
    let titleKey: String
    let captionKey: String
    var onClose: () -> Void

    var body: some View {
        ZStack {
            FT.Palette.scrim.opacity(0.4).ignoresSafeArea()
            VStack(spacing: 14) {
                Spacer()
                Image(systemName: "hammer.fill")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(FT.Palette.textMuted)
                Text(NSLocalizedString(titleKey, comment: ""))
                    .font(FT.Typography.sectionTitle)
                    .foregroundStyle(FT.Palette.textPrimary)
                Text(NSLocalizedString(captionKey, comment: ""))
                    .font(FT.Typography.body)
                    .foregroundStyle(FT.Palette.textSecondary)
                Text(NSLocalizedString("common.comingSoon", comment: ""))
                    .font(FT.Typography.caption)
                    .foregroundStyle(FT.Palette.textMuted)
                    .padding(.top, 4)
                Spacer()
                CTAButton(
                    title: NSLocalizedString("common.close", comment: ""),
                    style: .secondary,
                    action: onClose
                )
                .padding(.horizontal, FT.Layout.sideMargin)
                .padding(.bottom, 24)
            }
        }
    }
}

/// Drives the immersive ride cover: SessionView while travelling, ArrivalView
/// once the duration has elapsed (including the resume-after-relaunch case).
private struct RidePresenter: View {
    let ticket: Ticket

    @Environment(SessionStore.self) private var session

    private enum Stage { case riding, arrived }
    @State private var stage: Stage

    init(ticket: Ticket) {
        self.ticket = ticket
        // If the duration already elapsed while away, jump straight to arrival.
        _stage = State(initialValue: ticket.isArrived() ? .arrived : .riding)
    }

    var body: some View {
        switch stage {
        case .riding:
            SessionView(
                ticket: ticket,
                onArrive: {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        stage = .arrived
                    }
                },
                onEnd: { session.clear() }
            )
        case .arrived:
            ArrivalView(ticket: ticket, onDone: { session.clear() })
        }
    }
}

#Preview {
    ContentView()
        .environment(SessionStore())
}
