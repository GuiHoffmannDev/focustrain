import SwiftUI

/// The live ride: a full-screen geodesic map with a glowing train, an overlaid
/// countdown, route endpoints, distance remaining, a "fit route" toggle, the
/// Tunnel Mode toggle, and an end-ride control. All timing derives from the
/// ticket's `departDate`, so it resumes correctly after backgrounding.
struct SessionView: View {
    let ticket: Ticket
    /// Fired once the journey's full duration has elapsed.
    var onArrive: () -> Void
    /// Fired when the traveller ends the ride early.
    var onEnd: () -> Void

    @State private var model: SessionViewModel
    @State private var tunnel = InAppTunnelController()
    @State private var followTrain = true
    @State private var appeared = false
    @State private var showEndConfirm = false

    @Environment(\.scenePhase) private var scenePhase

    init(ticket: Ticket, onArrive: @escaping () -> Void, onEnd: @escaping () -> Void) {
        self.ticket = ticket
        self.onArrive = onArrive
        self.onEnd = onEnd
        _model = State(initialValue: SessionViewModel(ticket: ticket))
    }

    var body: some View {
        ZStack {
            RouteMapView(
                from: model.fromCoordinate,
                to: model.toCoordinate,
                fraction: model.progress,
                style: model.mapStyle,
                showLabels: UserDefaults.standard.bool(forKey: "mapShowLabels"),
                follow: followTrain
            )
            .ignoresSafeArea()

            // Legibility scrim top + bottom.
            scrim

            // Tunnel Mode active-state visual.
            TunnelHero(isActive: tunnel.isActive)
                .animation(.easeInOut(duration: 0.5), value: tunnel.isActive)

            VStack(spacing: 0) {
                topBar
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : -16)

                Spacer()

                countdownBlock
                    .opacity(appeared ? 1 : 0)
                    .scaleEffect(appeared ? 1 : 0.94)

                Spacer()

                bottomBar
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 24)
            }
            .padding(.horizontal, FT.Layout.sideMargin)
        }
        .background(FT.Palette.black)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            model.onArrive = onArrive
            model.start()
            // Default Tunnel to the traveller's quiet-carriage preference.
            if UserDefaults.standard.bool(forKey: "quietCarriageEnabled") {
                tunnel.enter()
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                appeared = true
            }
        }
        .onDisappear { model.stop() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { model.refresh() }
        }
        .confirmationDialog(
            NSLocalizedString("session.end", comment: ""),
            isPresented: $showEndConfirm,
            titleVisibility: .visible
        ) {
            Button(NSLocalizedString("session.end", comment: ""), role: .destructive, action: onEnd)
            Button(NSLocalizedString("common.back", comment: ""), role: .cancel) {}
        }
    }

    // MARK: - Scrim

    private var scrim: some View {
        VStack {
            LinearGradient(
                colors: [FT.Palette.black.opacity(0.75), .clear],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 220)
            Spacer()
            LinearGradient(
                colors: [.clear, FT.Palette.black.opacity(0.85)],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 280)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    // MARK: - Top bar (route + end control)

    private var topBar: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 8) {
                routeRow
                Text(model.ticket.code)
                    .font(FT.Typography.ticketField)
                    .foregroundStyle(FT.Palette.textMuted)
            }
            Spacer()
            Button { showEndConfirm = true } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(FT.Palette.white)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(FT.Palette.black.opacity(0.5)))
                    .overlay(Circle().stroke(FT.Palette.textMuted.opacity(0.3), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 8)
    }

    private var routeRow: some View {
        HStack(spacing: 10) {
            StationBadge(code: model.ticket.fromCode, variant: .rail)
            Image(systemName: "arrow.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(FT.Palette.textSecondary)
            StationBadge(code: model.ticket.toCode, variant: .brass)
        }
    }

    // MARK: - Countdown

    private var countdownBlock: some View {
        VStack(spacing: 10) {
            CountdownLabel(text: model.remainingText)
                .animation(.spring(response: 0.4, dampingFraction: 0.9), value: model.remainingText)

            HStack(spacing: 6) {
                Image(systemName: "point.topleft.down.curvedto.point.bottomright.up")
                    .font(.system(size: 12, weight: .bold))
                Text("\(NSLocalizedString("session.distance.remaining", comment: "")) · \(model.remainingDistanceText)")
                    .font(FT.Typography.caption)
            }
            .foregroundStyle(FT.Palette.textSecondary)
        }
    }

    // MARK: - Bottom bar (tunnel + fit)

    private var bottomBar: some View {
        VStack(spacing: 14) {
            tunnelToggle
            HStack(spacing: 12) {
                fitToggle
            }
        }
        .padding(.bottom, 16)
    }

    private var tunnelToggle: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
                tunnel.toggle()
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: tunnel.isActive ? "moon.zzz.fill" : "moon")
                    .font(.system(size: 17, weight: .bold))
                Text(NSLocalizedString(
                    tunnel.isActive ? "session.tunnel.on" : "session.tunnel.off",
                    comment: ""
                ))
                .font(FT.Typography.button)
            }
            .foregroundStyle(tunnel.isActive ? FT.Palette.ink : FT.Palette.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(tunnel.isActive ? FT.Palette.brandRail : FT.Palette.bgElevated.opacity(0.7))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(tunnel.isActive ? Color.clear : FT.Palette.textMuted.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var fitToggle: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
                followTrain.toggle()
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: followTrain ? "scope" : "tram.fill")
                    .font(.system(size: 14, weight: .bold))
                Text(NSLocalizedString(followTrain ? "session.fit" : "session.progress", comment: ""))
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundStyle(FT.Palette.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Capsule().fill(FT.Palette.bgElevated.opacity(0.5)))
        }
        .buttonStyle(.plain)
    }
}
