import SwiftUI

/// The live ride: a full-screen geodesic map with a glowing train. Chrome
/// floats on top — destination title at the top, side control pills hugging
/// the edges, and tiny time/distance metric tiles in the bottom corners.
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
    @State private var cameraMode: CameraMode = .centerTrain
    @State private var appeared = false
    @State private var mapStyle: MapStyle
    @State private var showMapStyleSheet = false
    @State private var showSoundSheet = false
    @AppStorage("mapShowLabels") private var mapShowLabels: Bool = true

    @Environment(\.scenePhase) private var scenePhase
    @Environment(SessionStore.self) private var session

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

                    SessionControlButton(
                        systemName: "music.note",
                        state: sound.selected != nil ? .active : .idle,
                        accessibilityLabel: NSLocalizedString("session.sound.a11y", comment: ""),
                        accessibilityValue: sound.selected?.rawValue ?? "off"
                    ) {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showSoundSheet = true
                    }
                }
                .opacity(appeared ? 1 : 0)
                .offset(x: appeared ? 0 : -30)

                Spacer()

                VStack(spacing: 12) {
                    SessionControlPill {
                        SessionControlButton(
                            systemName: "arrow.up.left.and.arrow.down.right",
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
                        showMapStyleSheet = true
                    }

                    SessionControlButton(
                        systemName: "tram.tunnel.fill",
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
        .onChange(of: mapStyle) { _, newValue in
            session.updateMapStyle(newValue)
        }
        .sheet(isPresented: $showMapStyleSheet) {
            NavigationStack {
                MapStyleSelector(selection: $mapStyle, showLabels: $mapShowLabels)
                    .padding()
                    .navigationTitle(Text(NSLocalizedString("session.mapstyle.title", comment: "")))
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                showMapStyleSheet = false
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(FT.Palette.textPrimary)
                                    .frame(width: 30, height: 30)
                                    .background(
                                        Circle().fill(FT.Palette.bgElevated.opacity(0.6))
                                    )
                            }
                        }
                    }
            }
            .presentationDetents([.fraction(0.55)])
            .presentationBackground(.ultraThinMaterial)
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showSoundSheet) {
            SoundSheet(sound: sound)
                .presentationDetents([.large])
                .presentationBackground(.ultraThinMaterial)
                .presentationDragIndicator(.visible)
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

}
