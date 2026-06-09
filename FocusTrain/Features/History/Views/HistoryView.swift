import SwiftUI
import SwiftData

/// Completed journeys as a bottom sheet, newest first, each re-rendered as the
/// stamped `TrainTicketCard` the traveller departed on. Topped by a pull-handle
/// header (drag indicator + title + close), filter chips (status, scenario,
/// sort), and an entry to the cumulative journey map (nested sheet).
struct HistoryView: View {
    /// Dismiss the sheet.
    var onClose: () -> Void

    @Query(sort: \Journey.date, order: .reverse) private var journeys: [Journey]

    @State private var appeared = false
    @State private var showMap = false

    @State private var statusFilter: StatusFilter = .all
    @State private var scenarioFilter: FocusScenario? = nil
    @State private var sortOrder: SortOrder = .recent

    enum StatusFilter: String, CaseIterable, Identifiable {
        case all, completed
        var id: String { rawValue }
        var labelKey: String {
            switch self {
            case .all:       return "history.status.all"
            case .completed: return "history.status.completed"
            }
        }
    }

    enum SortOrder: String, CaseIterable, Identifiable {
        case recent, oldest, duration
        var id: String { rawValue }
        var labelKey: String {
            switch self {
            case .recent:   return "history.sort.recent"
            case .oldest:   return "history.sort.oldest"
            case .duration: return "history.sort.duration"
            }
        }
    }

    private var streak: Int {
        StreakCalculator.currentStreak(from: journeys)
    }

    private var filteredJourneys: [Journey] {
        var items = journeys
        if let scenario = scenarioFilter {
            items = items.filter { $0.scenario == scenario.rawValue }
        }
        // Status: all journeys persisted here are completed rides — `.all`
        // and `.completed` resolve to the same set today but the control
        // is wired through so additional states can land without UI churn.
        switch sortOrder {
        case .recent:
            items.sort { $0.date > $1.date }
        case .oldest:
            items.sort { $0.date < $1.date }
        case .duration:
            items.sort { $0.durationMinutes > $1.durationMinutes }
        }
        return items
    }

    var body: some View {
        ZStack {
            FT.Palette.black.opacity(0.35).ignoresSafeArea()
            RadialGradient(
                colors: [FT.Palette.brandRail.opacity(0.06), .clear],
                center: .top, startRadius: 0, endRadius: 420
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, FT.Layout.sideMargin)
                    .padding(.top, 12)

                filterBar
                    .padding(.top, 14)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : -8)

                if filteredJourneys.isEmpty {
                    Spacer()
                    emptyState
                        .opacity(appeared ? 1 : 0)
                    Spacer()
                } else {
                    content
                }
            }
        }
        .sheet(isPresented: $showMap) {
            JourneyMapScreen(onBack: { showMap = false })
        }
        .onAppear {
            guard !appeared else { return }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                appeared = true
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center) {
            FTGlassIconButton(
                systemName: "map.fill",
                foreground: FT.Palette.brandRail,
                accessibilityLabel: "history.map.a11y"
            ) { showMap = true }

            Spacer()

            VStack(spacing: 2) {
                Text(NSLocalizedString("history.title", comment: ""))
                    .font(FT.Typography.sectionTitle)
                    .foregroundStyle(FT.Palette.white)
                streakLine
            }

            Spacer()

            FTGlassIconButton(
                systemName: "xmark",
                accessibilityLabel: "common.close",
                action: onClose
            )
        }
    }

    private var streakLine: some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(streak > 0 ? FT.Palette.brandBrass : FT.Palette.textMuted)
            Text("\(NSLocalizedString("history.streak", comment: "")): \(streak)")
                .font(FT.Typography.caption)
                .foregroundStyle(FT.Palette.textSecondary)
                .contentTransition(.numericText())
        }
    }

    // MARK: - Filter bar

    private var filterBar: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("history.filter.status")
            ScrollView(.horizontal, showsIndicators: false) {
                FTGlassContainer {
                    HStack(spacing: 8) {
                        ForEach(StatusFilter.allCases) { option in
                            FilterChip(
                                label: NSLocalizedString(option.labelKey, comment: ""),
                                isSelected: statusFilter == option
                            ) { statusFilter = option }
                        }
                    }
                    .padding(.horizontal, FT.Layout.sideMargin)
                }
            }

            sectionLabel("history.filter.scenario")
            ScrollView(.horizontal, showsIndicators: false) {
                FTGlassContainer {
                    HStack(spacing: 8) {
                        FilterChip(
                            label: NSLocalizedString("history.filter.all", comment: ""),
                            isSelected: scenarioFilter == nil
                        ) { scenarioFilter = nil }

                        ForEach(FocusScenario.allCases) { scenario in
                            FilterChip(
                                label: NSLocalizedString(scenario.displayKey, comment: ""),
                                systemImage: scenario.symbol,
                                tint: scenario.tint,
                                isSelected: scenarioFilter == scenario
                            ) { scenarioFilter = scenario }
                        }
                    }
                    .padding(.horizontal, FT.Layout.sideMargin)
                }
            }

            sectionLabel("history.filter.sort")
            ScrollView(.horizontal, showsIndicators: false) {
                FTGlassContainer {
                    HStack(spacing: 8) {
                        ForEach(SortOrder.allCases) { option in
                            FilterChip(
                                label: NSLocalizedString(option.labelKey, comment: ""),
                                isSelected: sortOrder == option
                            ) { sortOrder = option }
                        }
                    }
                    .padding(.horizontal, FT.Layout.sideMargin)
                }
            }
        }
    }

    private func sectionLabel(_ key: String) -> some View {
        Text(NSLocalizedString(key, comment: ""))
            .font(FT.Typography.caption)
            .foregroundStyle(FT.Palette.textMuted)
            .textCase(.uppercase)
            .padding(.horizontal, FT.Layout.sideMargin)
    }

    // MARK: - List

    private var content: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 20) {
                ForEach(Array(filteredJourneys.enumerated()), id: \.element.id) { index, journey in
                    ticket(journey)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 24)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.85)
                                .delay(min(Double(index) * 0.06, 0.4)),
                            value: appeared
                        )
                }
            }
            .padding(.horizontal, FT.Layout.sideMargin)
            .padding(.top, 18)
            .padding(.bottom, 40)
        }
    }

    private func ticket(_ journey: Journey) -> some View {
        let scenario = FocusScenario(rawValue: journey.scenario) ?? .forest
        return TrainTicketCard(
            fromCode: journey.fromCode,
            toCode: journey.toCode,
            fromName: journey.fromCity,
            toName: journey.toCity,
            scenarioTag: NSLocalizedString(scenario.displayKey, comment: ""),
            departLabel: journey.date.formatted(.dateTime.day().month().year()),
            durationLabel: "\(journey.durationMinutes) \(NSLocalizedString("compose.duration.minutes", comment: ""))",
            ticketCode: journey.code
        )
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tram.tunnel.fill")
                .font(.system(size: 52))
                .foregroundStyle(FT.Palette.textMuted)
            Text(NSLocalizedString("history.empty", comment: ""))
                .font(FT.Typography.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(FT.Palette.textSecondary)
        }
        .padding(.horizontal, FT.Layout.sideMargin)
    }
}

// MARK: - Chip

private struct FilterChip: View {
    let label: String
    var systemImage: String? = nil
    var tint: Color = FT.Palette.brandRail
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        FTGlassChip(
            isSelected: isSelected,
            tint: FT.Palette.white.opacity(0.75),
            idleForeground: FT.Palette.textSecondary,
            selectedForeground: FT.Palette.black,
            haptic: nil,
            action: action
        ) {
            HStack(spacing: 6) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(isSelected ? FT.Palette.black : tint)
                }
                Text(label)
                    .font(FT.Typography.caption.weight(.semibold))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }
}
