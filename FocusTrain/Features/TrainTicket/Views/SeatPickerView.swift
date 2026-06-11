import SwiftUI
import SwiftData
import UIKit

/// Last step before the ride: a scrollable top-down steam train. Tap a seat
/// and it morphs into the focus-reason modal; the chosen mode's icon fills the
/// seat; Confirm hands the ticket to the boarding pass.
struct SeatPickerView: View {
    let incomingTicket: Ticket
    var onDepart: (Ticket) -> Void
    var onBack: () -> Void

    @Environment(FocusModeStore.self) private var focusModeStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query private var journeys: [Journey]

    /// Interaction phases. `choosing`/`filled`/`departing` carry the seat code.
    private enum Phase: Equatable {
        case idle
        case choosing(String)
        case filled(String)
        case departing(String)
    }

    @State private var phase: Phase = .idle
    @State private var selectedDefault: FocusMode?
    @State private var selectedCustomID: UUID?
    @State private var showCustomSheet = false
    @State private var appeared = false
    @State private var pendingBoardingPass: Ticket?
    @State private var departOffset: CGFloat = 0
    @State private var departProgress: Double = 0
    @State private var contentFade: Double = 1
    @State private var contentHeight: CGFloat = 0
    @State private var viewportHeight: CGFloat = 0

    @Namespace private var seatNamespace

    private let layout = WagonLayout.standard
    private let morphSpring = Animation.spring(response: 0.42, dampingFraction: 0.86)

    private var usedSeats: Set<String> {
        SeatHistory.usedSeatCodes(in: journeys)
    }

    private var chosenSeat: String? {
        if case .choosing(let code) = phase { return code }
        return nil
    }

    private var isDeparting: Bool {
        if case .departing = phase { return true }
        return false
    }

    private var isScrollLocked: Bool {
        switch phase {
        case .choosing, .departing: return true
        case .idle, .filled:        return false
        }
    }

    /// Symbol/tint/name of whichever mode is selected (default or custom).
    private var chosenMode: (symbol: String, tint: Color, name: String)? {
        if let mode = selectedDefault {
            return (mode.symbol, mode.tint, mode.rawValue)
        }
        if let id = selectedCustomID,
           let custom = focusModeStore.customModes.first(where: { $0.id == id }) {
            return (custom.symbol, custom.tint, custom.name)
        }
        return nil
    }

    var body: some View {
        ZStack {
            FT.Palette.black.ignoresSafeArea()
            backdropGlow

            ScrollView(showsIndicators: false) {
                trainComposition
                    .padding(.horizontal, FT.Layout.sideMargin)
                    .padding(.top, 8)
                    .padding(.bottom, 160)
                    .opacity(appeared ? 1 : 0)
                    .scaleEffect(appeared ? 1 : 0.96)
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: {
                        contentHeight = $0
                    }
                    .offset(y: departOffset)
            }
            .scrollDisabled(isScrollLocked)
            .opacity(contentFade)

            if isDeparting {
                SpeedLinesOverlay(progress: departProgress)
            }

            confirmLayer
        }
        .overlayPreferenceValue(SeatBoundsKey.self) { anchors in
            modalOverlay(anchors)
        }
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: {
            viewportHeight = $0
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                // Plain button: the iOS 26 toolbar supplies the Liquid Glass
                // chrome; a custom background here would double it.
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(FT.Palette.white)
                }
                .disabled(isDeparting)
                .accessibilityLabel(Text("common.back"))
            }
        }
        .fullScreenCover(item: $pendingBoardingPass) { ticket in
            BoardingPassView(
                ticket: ticket,
                onTearComplete: { confirmedTicket in
                    pendingBoardingPass = nil
                    onDepart(confirmedTicket)
                },
                onCancel: { handleBoardingPassCancel() }
            )
        }
        .sheet(isPresented: $showCustomSheet) {
            CustomFocusModeSheet { mode in
                focusModeStore.add(mode)
                selectedCustomID = mode.id   // commits via onChange below
                selectedDefault = nil
            }
        }
        // Picking a chip commits the choice. The `new != nil` guard is load-
        // bearing: the two selections are mutually exclusive, so setting one
        // always clears the other — that paired clear fires the sibling
        // onChange with `nil`, which must be ignored (not treated as a commit).
        .onChange(of: selectedDefault) { _, new in
            if new != nil { commitChoice() }
        }
        .onChange(of: selectedCustomID) { _, new in
            if new != nil { commitChoice() }
        }
        .onAppear {
            guard !appeared else { return }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                appeared = true
            }
        }
    }

    // MARK: - Backdrop

    private var backdropGlow: some View {
        RadialGradient(
            colors: [FT.Palette.brandRail.opacity(0.10), .clear],
            center: .top,
            startRadius: 0,
            endRadius: 420
        )
        .ignoresSafeArea()
    }

    // MARK: - Train

    private var trainComposition: some View {
        VStack(spacing: 0) {
            SteamLocomotiveView(steamIntensity: isDeparting ? 1.0 : 0.35)
            TrainCouplingView()
            WagonView(
                layout: layout,
                seatState: seatState,
                hiddenSeat: chosenSeat,
                namespace: seatNamespace,
                onSelect: handleSeatTap
            )
        }
    }

    private func seatState(_ code: String) -> SeatTile.State {
        let filledCode: String? = {
            switch phase {
            case .filled(let c), .departing(let c): return c
            default: return nil
            }
        }()
        if code == filledCode, let mode = chosenMode {
            return .filled(symbol: mode.symbol, tint: mode.tint)
        }
        if usedSeats.contains(code) { return .previouslyUsed }
        return .available
    }

    // MARK: - Modal overlay (scrim + morphing card)

    @ViewBuilder
    private func modalOverlay(_ anchors: [String: Anchor<CGRect>]) -> some View {
        GeometryReader { proxy in
            ZStack {
                if case .choosing(let code) = phase {
                    FT.Palette.black.opacity(0.55)
                        .ignoresSafeArea()
                        .contentShape(Rectangle())
                        .onTapGesture { cancelChoice() }
                        .transition(.opacity)

                    let cardWidth = proxy.size.width - FT.Layout.sideMargin * 2
                    let seatMidY = anchors[code].map { proxy[$0].midY } ?? proxy.size.height / 2
                    let y = min(max(seatMidY, 200), proxy.size.height - 220)

                    FocusReasonCard(
                        seatCode: code,
                        selectedDefault: $selectedDefault,
                        selectedCustomID: $selectedCustomID,
                        customModes: focusModeStore.customModes,
                        onTapAdd: { showCustomSheet = true },
                        onDeleteCustom: handleDeleteCustom
                    )
                    .frame(width: cardWidth)
                    .matchedGeometryEffect(id: code, in: seatNamespace)
                    .position(x: proxy.size.width / 2, y: y)
                }
            }
        }
    }

    // MARK: - Confirm pill

    private var confirmLayer: some View {
        VStack {
            Spacer()
            if case .filled = phase, chosenMode != nil {
                CTAButton(
                    title: NSLocalizedString("seatPicker.confirmCta", comment: ""),
                    style: .primary,
                    action: handleConfirm
                )
                .padding(.horizontal, FT.Layout.sideMargin)
                .padding(.bottom, 12)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.82), value: phase)
    }

    // MARK: - Actions

    private func handleSeatTap(_ code: String) {
        guard !isDeparting else { return }
        // Tapping any seat (including a re-tap on the filled one) clears the
        // previous pick and opens the modal there — single selection.
        selectedDefault = nil
        selectedCustomID = nil
        withAnimation(morphSpring) {
            phase = .choosing(code)
        }
    }

    private func cancelChoice() {
        selectedDefault = nil
        selectedCustomID = nil
        withAnimation(morphSpring) {
            phase = .idle
        }
    }

    /// A chip was picked while the modal is open: morph the card back into the
    /// seat, now filled with the mode's icon and tint.
    private func commitChoice() {
        guard case .choosing(let code) = phase else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(morphSpring) {
            phase = .filled(code)
        }
    }

    private func handleDeleteCustom(_ mode: CustomFocusMode) {
        if selectedCustomID == mode.id { selectedCustomID = nil }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            focusModeStore.remove(mode)
        }
    }

    private func handleConfirm() {
        guard case .filled(let seat) = phase, let mode = chosenMode else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        var finalTicket = incomingTicket
        finalTicket.seatCode = seat
        finalTicket.focusMode = mode.name
        phase = .departing(seat)

        if reduceMotion {
            withAnimation(.easeInOut(duration: 0.3)) { contentFade = 0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
                pendingBoardingPass = finalTicket
            }
            return
        }

        // The run: heavy start, then full steam — train exits the screen top.
        let distance = contentHeight + viewportHeight
        withAnimation(.timingCurve(0.85, 0.0, 0.9, 0.4, duration: 1.4)) {
            departOffset = -distance
        }
        withAnimation(.easeIn(duration: 1.0)) { departProgress = 1 }
        scheduleDepartureHaptics()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.45) {
            pendingBoardingPass = finalTicket
        }
    }

    /// Light impacts at increasing pace — wheels biting as the train speeds up.
    private func scheduleDepartureHaptics() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        for delay in [0.25, 0.55, 0.8, 0.98, 1.12, 1.24] {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                guard isDeparting else { return }
                generator.impactOccurred(intensity: 0.6 + 0.4 * delay / 1.3)
            }
        }
    }

    private func handleBoardingPassCancel() {
        pendingBoardingPass = nil
        departProgress = 0
        contentFade = 1
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) { departOffset = 0 }
        if case .departing(let seat) = phase {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                phase = .filled(seat)
            }
        }
    }
}

extension Ticket: Identifiable {
    var id: String { code }
}
