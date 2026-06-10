import SwiftUI
import SwiftData
import UIKit

/// Last step before the ride: pick a seat in the wagon and an intention chip.
/// Mirrors the visual cadence of the compose flow (black bg + brandRail
/// backdrop glow + spring reveal + back chevron toolbar) so the embarkation
/// flow feels continuous.
struct SeatPickerView: View {
    let incomingTicket: Ticket
    var onDepart: (Ticket) -> Void
    var onBack: () -> Void

    @Environment(FocusModeStore.self) private var focusModeStore
    @Query private var journeys: [Journey]

    @State private var selectedSeat: String?
    @State private var selectedDefault: FocusMode?
    @State private var selectedCustomID: UUID?
    @State private var showCustomSheet: Bool = false
    @State private var appeared: Bool = false
    @State private var pendingBoardingPass: Ticket?

    private let layout = WagonLayout.standard

    private var usedSeats: Set<String> {
        SeatHistory.usedSeatCodes(in: journeys)
    }

    private var canDepart: Bool {
        selectedSeat != nil && (selectedDefault != nil || selectedCustomID != nil)
    }

    var body: some View {
        ZStack {
            FT.Palette.bgPrimary.ignoresSafeArea()
            backdropGlow

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    header
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 12)

                    WagonView(
                        layout: layout,
                        selectedSeat: selectedSeat,
                        usedSeats: usedSeats,
                        onSelect: handleSeatTap
                    )
                    .opacity(appeared ? 1 : 0)
                    .scaleEffect(appeared ? 1 : 0.96)
                }
                .padding(.horizontal, FT.Layout.sideMargin)
                .padding(.top, 8)
                .padding(.bottom, selectedSeat == nil ? 140 : 280)
            }

            bottomOverlay
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                // Plain button: the iOS 26 toolbar supplies the Liquid Glass
                // chrome; a custom background here would double it.
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(FT.Palette.textPrimary)
                }
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
                onCancel: { pendingBoardingPass = nil }
            )
        }
        .sheet(isPresented: $showCustomSheet) {
            CustomFocusModeSheet { mode in
                focusModeStore.add(mode)
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    selectedCustomID = mode.id
                    selectedDefault = nil
                }
            }
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

    // MARK: - Header

    private var header: some View {
        Text(NSLocalizedString("seatPicker.title", comment: ""))
            .font(FT.Typography.sectionTitle)
            .foregroundStyle(FT.Palette.textPrimary)
    }

    // MARK: - Bottom overlay (confirm card + CTA)

    private var bottomOverlay: some View {
        VStack(spacing: 16) {
            Spacer()

            if let seat = selectedSeat {
                SeatConfirmCard(
                    seatCode: seat,
                    selectedDefault: $selectedDefault,
                    selectedCustomID: $selectedCustomID,
                    customModes: focusModeStore.customModes,
                    onTapAdd: { showCustomSheet = true },
                    onDeleteCustom: handleDeleteCustom
                )
                .padding(.horizontal, FT.Layout.sideMargin)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            CTAButton(
                title: NSLocalizedString("seatPicker.depart", comment: ""),
                style: .primary,
                icon: "arrow.right",
                action: handleDepart
            )
            .padding(.horizontal, FT.Layout.sideMargin)
            .padding(.bottom, 12)
            .opacity(canDepart ? 1 : 0.4)
            .allowsHitTesting(canDepart)
        }
        .background(
            LinearGradient(
                colors: [FT.Palette.scrim.opacity(0), FT.Palette.scrim],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)
        )
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 24)
        .animation(.spring(response: 0.45, dampingFraction: 0.82), value: selectedSeat)
    }

    // MARK: - Actions

    private func handleSeatTap(_ code: String) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            if selectedSeat == code {
                selectedSeat = nil
            } else {
                selectedSeat = code
            }
        }
    }

    private func handleDeleteCustom(_ mode: CustomFocusMode) {
        if selectedCustomID == mode.id {
            selectedCustomID = nil
        }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            focusModeStore.remove(mode)
        }
    }

    private func handleDepart() {
        guard canDepart, let seat = selectedSeat else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        let modeName: String? = {
            if let mode = selectedDefault { return mode.rawValue }
            if let id = selectedCustomID,
               let custom = focusModeStore.customModes.first(where: { $0.id == id }) {
                return custom.name
            }
            return nil
        }()

        var finalTicket = incomingTicket
        finalTicket.seatCode = seat
        finalTicket.focusMode = modeName
        pendingBoardingPass = finalTicket
    }
}

extension Ticket: Identifiable {
    var id: String { code }
}
