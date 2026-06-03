import SwiftUI

/// The live ride: a full-screen geodesic map with a glowing train. Chrome
/// floats on top — destination title at the top, side control pills hugging
/// the edges, and tiny time/distance metric tiles in the bottom corners.
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
    @State private var scenario: FocusScenario
    @State private var mapStyle: MapStyle

    @Environment(\.scenePhase) private var scenePhase
    @Environment(SessionStore.self) private var session

    init(ticket: Ticket, onArrive: @escaping () -> Void, onEnd: @escaping () -> Void) {
        self.ticket = ticket
        self.onArrive = onArrive
        self.onEnd = onEnd
        _model = State(initialValue: SessionViewModel(ticket: ticket))
        _scenario = State(initialValue: FocusScenario(rawValue: ticket.scenario) ?? .forest)
        _mapStyle = State(initialValue: MapStyle(rawValue: ticket.mapStyle) ?? .monochrome)
    }

    var body: some View {
        ZStack {
            RouteMapView(
                from: model.fromCoordinate,
                to: model.toCoordinate,
                fraction: model.progress,
                style: mapStyle,
                showLabels: UserDefaults.standard.bool(forKey: "mapShowLabels"),
                follow: followTrain
            )
            .ignoresSafeArea()

            FT.Palette.black
                .opacity(model.isPaused ? 0.3 : 0)
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .animation(.easeInOut(duration: 0.3), value: model.isPaused)

            scrim

            TunnelHero(isActive: tunnel.isActive)
                .animation(.easeInOut(duration: 0.5), value: tunnel.isActive)

            // Top: destination title (centered) + end button (top-right).
            VStack {
                ZStack {
                    SessionTitleLabel(text: destinationName)
                        .padding(.horizontal, 60) // leave room for end button
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : -16)

                    HStack {
                        Spacer()
                        if model.isPaused {
                            SessionEndButton(onEnd: onEnd)
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared ? 0 : -16)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .animation(.spring(response: 0.4, dampingFraction: 0.82), value: model.isPaused)
                }
                .padding(.top, 8)
                Spacer()
            }
            .padding(.horizontal, FT.Layout.sideMargin)

            // Left + right control pills, vertically centered on the screen.
            HStack {
                SessionControlPill {
                    SessionControlButton(
                        systemName: model.isPaused ? "play.fill" : "pause.fill",
                        state: model.isPaused ? .active : .idle,
                        accessibilityLabel: NSLocalizedString(
                            model.isPaused ? "session.resume" : "session.pause",
                            comment: ""
                        ),
                        accessibilityValue: model.isPaused ? "paused" : "running"
                    ) {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
                            model.togglePause()
                        }
                    }

                    SessionMusicMenu(
                        scenario: $scenario,
                        onSelect: { session.updateScenario($0) }
                    )
                }
                .opacity(appeared ? 1 : 0)
                .offset(x: appeared ? 0 : -30)

                Spacer()

                SessionControlPill {
                    SessionControlButton(
                        systemName: tunnel.isActive ? "moon.zzz.fill" : "moon",
                        state: tunnel.isActive ? .active : .idle,
                        accessibilityLabel: NSLocalizedString(
                            tunnel.isActive ? "session.tunnel.on" : "session.tunnel.off",
                            comment: ""
                        ),
                        accessibilityValue: tunnel.isActive ? "on" : "off"
                    ) {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
                            tunnel.toggle()
                        }
                    }

                    SessionControlButton(
                        systemName: followTrain ? "scope" : "tram.fill",
                        state: followTrain ? .active : .idle,
                        accessibilityLabel: NSLocalizedString(
                            followTrain ? "session.fit" : "session.progress",
                            comment: ""
                        ),
                        accessibilityValue: followTrain ? "on" : "off"
                    ) {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
                            followTrain.toggle()
                        }
                    }

                    mapStyleMenu
                }
                .opacity(appeared ? 1 : 0)
                .offset(x: appeared ? 0 : 30)
            }
            .padding(.horizontal, FT.Layout.sideMargin)

            // Bottom: time + distance tiles.
            VStack {
                Spacer()
                HStack(alignment: .bottom) {
                    SessionMetricTile(
                        label: NSLocalizedString("session.time.remaining", comment: ""),
                        value: model.remainingMinutesText,
                        alignment: .leading
                    )
                    Spacer()
                    SessionMetricTile(
                        label: NSLocalizedString("session.distance.remaining", comment: ""),
                        value: model.remainingDistanceText,
                        alignment: .trailing
                    )
                }
                .padding(.bottom, 16)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 24)
            }
            .padding(.horizontal, FT.Layout.sideMargin)
        }
        .background(FT.Palette.black)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            model.store = session
            model.onArrive = onArrive
            model.start()
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
    }

    // MARK: - Destination name

    private var destinationName: String {
        StationPool.station(forCode: ticket.toCode)?.city ?? ticket.toCode
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

    // MARK: - Map style menu

    private var mapStyleMenu: some View {
        Menu {
            ForEach(MapStyle.allCases) { option in
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    mapStyle = option
                    session.updateMapStyle(option)
                } label: {
                    Label {
                        Text(LocalizedStringKey(option.displayKey))
                    } icon: {
                        Image(systemName: mapStyle == option ? "checkmark" : option.symbol)
                    }
                }
            }
        } label: {
            Image(systemName: "map")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(FT.Palette.white)
                .frame(width: 40, height: 40)
                .background(Circle().fill(FT.Palette.black.opacity(0.5)))
                .overlay(Circle().stroke(FT.Palette.textMuted.opacity(0.3), lineWidth: 1))
        }
        .accessibilityLabel(Text(NSLocalizedString("session.mapstyle.a11y", comment: "")))
    }
}
