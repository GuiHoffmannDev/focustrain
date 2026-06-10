import SwiftUI

/// The live ride: a full-screen geodesic map with a glowing train. Chrome
/// floats on top — control pills hug the top corners; tiny time/distance
/// metric tiles sit in the bottom corners. While paused, the right-side pill
/// stack collapses into a single 3-dots button that opens an in-place pause menu.
struct SessionView: View {
    enum CameraMode {
        case fitRoute
        case centerTrain
    }

    let ticket: Ticket
    /// Fired once the journey's full duration has elapsed.
    var onArrive: () -> Void
    /// Fired when the traveller ends the ride early.
    var onEnd: () -> Void

    @State private var model: SessionViewModel
    @State private var tunnel = InAppTunnelController()
    @State private var sound = AmbientSoundController()
    @State private var focusMode = FocusModeController()
    @State private var awake = ScreenAwakeController()
    @State private var cameraMode: CameraMode = .centerTrain
    @State private var appeared = false
    @State private var mapStyle: MapStyle
    @State private var activeSheet: SessionSheet?
    @State private var showMenu = false
    @State private var showSound = false

    private enum SessionSheet: String, Identifiable {
        case mapStyle
        var id: String { rawValue }
    }
    @AppStorage("mapShowLabels") private var mapShowLabels: Bool = true

    @Environment(\.scenePhase) private var scenePhase
    @Environment(SessionStore.self) private var session
    @Environment(\.colorScheme) private var colorScheme

    /// Whether the map under the chrome reads dark (so scrims/text stay on the
    /// dark side). terra/satellite are dark imagery in both schemes.
    private var darkChrome: Bool { mapStyle.usesDarkChrome(for: colorScheme) }

    init(ticket: Ticket, onArrive: @escaping () -> Void, onEnd: @escaping () -> Void) {
        self.ticket = ticket
        self.onArrive = onArrive
        self.onEnd = onEnd
        _model = State(initialValue: SessionViewModel(ticket: ticket))
        _mapStyle = State(initialValue: MapStyle(rawValue: ticket.mapStyle) ?? .monochrome)
    }

    var body: some View {
        ZStack {
            RouteMapView(
                from: model.fromCoordinate,
                to: model.toCoordinate,
                fraction: model.progress,
                style: mapStyle,
                showLabels: mapShowLabels,
                follow: cameraMode == .centerTrain
            )
            .ignoresSafeArea()
            .saturation(mapStyle == .monochrome ? 0 : 1)
            .allowsHitTesting(false)

            (darkChrome ? FT.Palette.black : FT.Palette.scrim)
                .opacity(model.isPaused ? 0.85 : 0)
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .animation(.easeInOut(duration: 0.3), value: model.isPaused)

            scrim

            TunnelHero(isActive: tunnel.isActive)
                .animation(.easeInOut(duration: 0.5), value: tunnel.isActive)

            // Top chrome: title centered, pills in the corners.
            VStack {
                topChromeRow
                    .padding(.top, 8)
                Spacer()
            }
            .padding(.horizontal, FT.Layout.sideMargin)
            .opacity(showMenu ? 0 : (appeared ? 1 : 0))
            .animation(.easeInOut(duration: 0.25), value: showMenu)

            // Bottom: time + distance tiles.
            VStack {
                Spacer()
                HStack(alignment: .bottom) {
                    SessionMetricTile(
                        label: NSLocalizedString("session.time.remaining", comment: ""),
                        value: model.remainingMinutesText,
                        alignment: .leading,
                        onDarkBackdrop: darkChrome
                    )
                    Spacer()
                    SessionMetricTile(
                        label: NSLocalizedString("session.distance.remaining", comment: ""),
                        value: model.remainingDistanceText,
                        alignment: .trailing,
                        onDarkBackdrop: darkChrome
                    )
                }
                .padding(.bottom, 16)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 24)
            }
            .padding(.horizontal, FT.Layout.sideMargin)
            .opacity(showMenu ? 0 : 1)
            .animation(.easeInOut(duration: 0.25), value: showMenu)

            if model.isPaused && !showMenu {
                pausedIndicator
                    .transition(.opacity)
                    .zIndex(11)
            }

            if showMenu {
                SessionPauseMenu(
                    awakePolicy: awake.policy,
                    focusOn: focusMode.isOn,
                    onGiveUp: handleGiveUp,
                    onAirplaneTap: handleAirplane,
                    onAwakeTap: handleAwakeCycle,
                    onDismiss: { withAnimation(.easeInOut(duration: 0.25)) { showMenu = false } }
                )
                .transition(.opacity)
                .zIndex(10)
            }

            if showSound {
                SoundOverlay(
                    sound: sound,
                    onDismiss: { withAnimation(.easeInOut(duration: 0.25)) { showSound = false } }
                )
                .transition(.opacity)
                .zIndex(10)
            }
        }
        .background(FT.Palette.bgPrimary)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            model.store = session
            model.onArrive = onArrive
            model.start()
            if UserDefaults.standard.bool(forKey: "quietCarriageEnabled") {
                tunnel.enter()
            }
            awake.apply(isPaused: model.isPaused)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                appeared = true
            }
        }
        .onDisappear {
            model.stop()
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { model.refresh() }
        }
        .onChange(of: mapStyle) { _, newValue in
            session.updateMapStyle(newValue)
        }
        .onChange(of: model.isPaused) { _, _ in
            awake.apply(isPaused: model.isPaused)
        }
        .onChange(of: awake.policy) { _, _ in
            awake.apply(isPaused: model.isPaused)
        }
        .sheet(item: $activeSheet) { kind in
            switch kind {
            case .mapStyle:
                NavigationStack {
                    MapStyleSelector(selection: $mapStyle, showLabels: $mapShowLabels)
                        .padding()
                        .navigationTitle(Text(NSLocalizedString("session.mapstyle.title", comment: "")))
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                // Plain button: the iOS 26 toolbar supplies the
                                // Liquid Glass chrome; a custom background here
                                // would double it.
                                Button {
                                    activeSheet = nil
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(FT.Palette.textPrimary)
                                }
                                .accessibilityLabel(Text("common.close"))
                            }
                        }
                }
                .presentationDetents([.fraction(0.55)])
                .presentationBackground(.ultraThinMaterial)
                .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Top chrome row

    private var topChromeRow: some View {
        HStack(alignment: .top) {
            leftStack
            Spacer()
            rightStack
        }
    }

    private var leftStack: some View {
        VStack(spacing: 12) {
            SessionControlButton(
                systemName: model.isPaused ? "play.fill" : "pause.fill",
                state: .idle,
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

            SessionControlButton(
                systemName: "music.note",
                state: .idle,
                accessibilityLabel: NSLocalizedString("session.sound.a11y", comment: ""),
                accessibilityValue: sound.selected?.rawValue ?? "off"
            ) {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(.easeInOut(duration: 0.25)) {
                    showSound = true
                }
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(x: appeared ? 0 : -30)
    }

    @ViewBuilder
    private var rightStack: some View {
        ZStack(alignment: .top) {
            if model.isPaused {
                SessionEllipsisButton(isMenuOpen: $showMenu)
                    .transition(.opacity)
            } else {
                runningRightColumn
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: model.isPaused)
        .opacity(appeared ? 1 : 0)
        .offset(x: appeared ? 0 : 30)
    }

    private var runningRightColumn: some View {
        VStack(spacing: 12) {
            SessionControlPill {
                SessionControlButton(
                    systemName: "point.topleft.down.to.point.bottomright.curvepath",
                    state: cameraMode == .fitRoute ? .active : .idle,
                    accessibilityLabel: NSLocalizedString("session.fit.route", comment: ""),
                    accessibilityValue: cameraMode == .fitRoute ? "on" : "off"
                ) {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
                        cameraMode = .fitRoute
                    }
                }

                SessionControlButton(
                    systemName: "scope",
                    state: cameraMode == .centerTrain ? .active : .idle,
                    accessibilityLabel: NSLocalizedString("session.center.train", comment: ""),
                    accessibilityValue: cameraMode == .centerTrain ? "on" : "off"
                ) {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
                        cameraMode = .centerTrain
                    }
                }
            }

            SessionControlButton(
                systemName: "map",
                state: .idle,
                accessibilityLabel: NSLocalizedString("session.mapstyle.a11y", comment: "")
            ) {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                activeSheet = .mapStyle
            }

            SessionControlButton(
                systemName: "train.side.rear.car",
                state: tunnel.isActive ? .active : .idle,
                accessibilityLabel: NSLocalizedString(
                    tunnel.isActive ? "session.rail.on" : "session.rail.off",
                    comment: ""
                ),
                accessibilityValue: tunnel.isActive ? "on" : "off"
            ) {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
                    tunnel.toggle()
                }
            }
        }
    }

    // MARK: - Menu actions

    private func handleGiveUp() {
        onEnd()
    }

    private func handleAirplane() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        Task { await focusMode.toggle() }
    }

    private func handleAwakeCycle() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        awake.cycle()
    }

    // MARK: - Paused indicator

    /// Centered "Paused / MM:SS" block shown while paused — the muted word
    /// stacked over the focus time accrued so far (pauses excluded).
    private var pausedIndicator: some View {
        VStack(spacing: 2) {
            Text(NSLocalizedString("session.paused", comment: "Paused state label"))
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(FT.Palette.textMuted)
            Text(model.elapsedText)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(darkChrome ? FT.Palette.white : FT.Palette.textPrimary)
                .shadow(color: FT.Palette.shadowSoft, radius: 3, x: 0, y: 1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .padding(.bottom, 110)
        .allowsHitTesting(false)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Scrim

    private var scrim: some View {
        let base = darkChrome ? FT.Palette.black : FT.Palette.scrim
        return VStack {
            LinearGradient(
                colors: [base.opacity(0.75), .clear],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 220)
            Spacer()
            LinearGradient(
                colors: [.clear, base.opacity(0.85)],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 280)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

}
