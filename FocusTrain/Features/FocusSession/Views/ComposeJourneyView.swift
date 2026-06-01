import SwiftUI

struct ComposeJourneyView: View {
    /// Called with the freshly-built ticket when the user departs.
    var onDepart: (Ticket) -> Void
    var onBack: () -> Void

    @State private var model = ComposeJourneyViewModel()
    @State private var appeared = false

    var body: some View {
        ZStack {
            FT.Palette.black.ignoresSafeArea()
            backdropGlow

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    header
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 12)

                    ticketPreview
                        .opacity(appeared ? 1 : 0)
                        .scaleEffect(appeared ? 1 : 0.96)

                    rerollButton
                        .opacity(appeared ? 1 : 0)

                    durationSection
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 16)

                    scenarioSection
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 18)
                }
                .padding(.horizontal, FT.Layout.sideMargin)
                .padding(.top, 8)
                .padding(.bottom, 140)
            }

            departBar
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 24)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(FT.Palette.white)
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
        Text(NSLocalizedString("compose.title", comment: ""))
            .font(FT.Typography.sectionTitle)
            .foregroundStyle(FT.Palette.white)
    }

    // MARK: - Ticket preview

    private var ticketPreview: some View {
        TrainTicketCard(
            fromCode: model.from.code,
            toCode: model.to.code,
            fromName: model.from.city,
            toName: model.to.city,
            scenarioTag: NSLocalizedString(model.scenario.displayKey, comment: ""),
            departLabel: Date.now.formatted(date: .omitted, time: .shortened),
            durationLabel: "\(model.duration.minutes) \(NSLocalizedString("compose.duration.minutes", comment: ""))",
            ticketCode: "FT-••••"
        )
        .animation(.spring(response: 0.45, dampingFraction: 0.82), value: model.from)
        .animation(.spring(response: 0.45, dampingFraction: 0.82), value: model.to)
    }

    private var rerollButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                model.reroll()
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "shuffle")
                    .font(.system(size: 14, weight: .bold))
                Text(NSLocalizedString("compose.route.reroll", comment: ""))
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundStyle(FT.Palette.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                Capsule().fill(FT.Palette.bgElevated.opacity(0.5))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Duration

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel(NSLocalizedString("compose.duration.title", comment: ""))

            HStack(spacing: 10) {
                ForEach(SessionDuration.allCases) { option in
                    durationChip(option)
                }
            }
        }
    }

    private func durationChip(_ option: SessionDuration) -> some View {
        let isSelected = model.duration == option
        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                model.duration = option
            }
        } label: {
            VStack(spacing: 2) {
                Text(option.label)
                    .font(.system(size: 24, weight: .black))
                Text(NSLocalizedString("compose.duration.minutes", comment: ""))
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.5)
            }
            .foregroundStyle(isSelected ? FT.Palette.ink : FT.Palette.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(isSelected ? FT.Palette.brandRail : FT.Palette.bgElevated.opacity(0.6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(isSelected ? Color.clear : FT.Palette.textMuted.opacity(0.25), lineWidth: 1)
            )
            .scaleEffect(isSelected ? 1.04 : 1.0)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Scenario

    private var scenarioSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel(NSLocalizedString("compose.scenario.title", comment: ""))
            ScenarioChips(selection: $model.scenario)
        }
    }

    // MARK: - Depart bar

    private var departBar: some View {
        VStack {
            Spacer()
            CTAButton(
                title: NSLocalizedString("compose.depart", comment: ""),
                style: .primary,
                icon: "arrow.right",
                action: {
                    onDepart(model.makeTicket())
                }
            )
            .padding(.horizontal, FT.Layout.sideMargin)
            .padding(.bottom, 12)
            .background(
                LinearGradient(
                    colors: [FT.Palette.black.opacity(0), FT.Palette.black],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)
            )
        }
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 12, weight: .bold))
            .tracking(1.5)
            .foregroundStyle(FT.Palette.textMuted)
    }
}
