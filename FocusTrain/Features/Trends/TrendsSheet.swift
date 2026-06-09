import SwiftUI
import SwiftData
import CoreLocation
import UIKit

/// Cinematic stats sheet — replaces the `ComingSoonSheet` stub for Trends.
/// Pull-handle header + custom segmented range picker (Total/Week/Month/Year)
/// + 2×2 glass card grid with the headline numbers + a paywalled focus-time
/// detail card showing a mocked weekly bar chart.
struct TrendsSheet: View {
    var onClose: () -> Void

    @Query(sort: \Journey.date) private var journeys: [Journey]

    @State private var range: Range = .total
    @State private var appeared = false

    enum Range: String, CaseIterable, Identifiable {
        case total, week, month, year
        var id: String { rawValue }
        var labelKey: String {
            switch self {
            case .total: return "trends.tab.total"
            case .week:  return "trends.tab.week"
            case .month: return "trends.tab.month"
            case .year:  return "trends.tab.year"
            }
        }
        /// Inclusive lower bound for filtering. `nil` means no lower bound.
        func lowerBound(now: Date = .now, calendar: Calendar = .current) -> Date? {
            let start = calendar.startOfDay(for: now)
            switch self {
            case .total: return nil
            case .week:  return calendar.date(byAdding: .day, value: -7, to: start)
            case .month: return calendar.date(byAdding: .day, value: -30, to: start)
            case .year:  return calendar.date(byAdding: .day, value: -365, to: start)
            }
        }
    }

    private var filtered: [Journey] {
        guard let lower = range.lowerBound() else { return journeys }
        return journeys.filter { $0.date >= lower }
    }

    private var journeyCount: Int { filtered.count }

    private var stationCount: Int {
        var set: Set<String> = []
        for j in filtered {
            set.insert(j.fromCity)
            set.insert(j.toCity)
        }
        return set.count
    }

    private var distanceKm: Int {
        let total = filtered.reduce(0.0) { acc, j in
            let a = CLLocation(latitude: j.fromLat, longitude: j.fromLon)
            let b = CLLocation(latitude: j.toLat,   longitude: j.toLon)
            return acc + a.distance(from: b)
        }
        return Int((total / 1000.0).rounded())
    }

    private var focusMinutes: Int {
        filtered.reduce(0) { $0 + $1.durationMinutes }
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

                RangePicker(selection: $range)
                    .padding(.horizontal, FT.Layout.sideMargin)
                    .padding(.top, 18)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : -8)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        grid
                        focusDetailCard
                    }
                    .padding(.horizontal, FT.Layout.sideMargin)
                    .padding(.top, 18)
                    .padding(.bottom, 40)
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

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center) {
            Color.clear.frame(width: 40, height: 40)
            Spacer()
            Text(NSLocalizedString("trends.title", comment: ""))
                .font(FT.Typography.sectionTitle)
                .foregroundStyle(FT.Palette.white)
            Spacer()
            FTGlassIconButton(
                systemName: "xmark",
                accessibilityLabel: "common.close",
                action: onClose
            )
        }
    }

    // MARK: - Grid

    private var grid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)],
            spacing: 14
        ) {
            StatCard(
                systemImage: "tram.fill",
                value: "\(journeyCount)",
                labelKey: "trends.card.journeys"
            )
            StatCard(
                systemImage: "mappin.and.ellipse",
                value: "\(stationCount)",
                labelKey: "trends.card.stations"
            )
            StatCard(
                systemImage: "point.topleft.down.curvedto.point.bottomright.up",
                value: "\(distanceKm)",
                labelKey: "trends.card.distance",
                unitKey: "trends.unit.km"
            )
            StatCard(
                systemImage: "timer",
                value: "\(focusMinutes)",
                labelKey: "trends.card.focusTime",
                unitKey: "trends.unit.minutes"
            )
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 12)
    }

    // MARK: - Focus detail (paywalled mock)

    private var focusDetailCard: some View {
        ZStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(FT.Palette.brandRail)
                    Text(NSLocalizedString("trends.focusTime.detailTitle", comment: ""))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(FT.Palette.white)
                    Spacer()
                }
                WeeklyBarsChart()
                    .frame(height: 120)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.clear)
                    .ftGlassRounded(cornerRadius: 20)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .blur(radius: 6)

            VStack(spacing: 12) {
                Spacer(minLength: 28)
                Image(systemName: "lock.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(FT.Palette.brandBrass)
                Text(NSLocalizedString("trends.paywall.title", comment: ""))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(FT.Palette.white)
                    .multilineTextAlignment(.center)
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }) {
                    Text(NSLocalizedString("trends.paywall.cta", comment: ""))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(FT.Palette.black)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(
                            Capsule(style: .continuous)
                                .fill(.clear)
                                .ftGlassCapsule(interactive: true, tint: FT.Palette.white.opacity(0.75))
                        )
                }
                .buttonStyle(.plain)
                Spacer(minLength: 18)
            }
            .frame(maxWidth: .infinity)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 12)
    }
}

// MARK: - Stat card

private struct StatCard: View {
    let systemImage: String
    let value: String
    let labelKey: String
    var unitKey: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(FT.Palette.brandRail)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 12)

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 36, weight: .heavy))
                    .foregroundStyle(FT.Palette.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                if let unitKey {
                    Text(NSLocalizedString(unitKey, comment: ""))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(FT.Palette.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)

            Spacer(minLength: 8)

            Text(NSLocalizedString(labelKey, comment: ""))
                .font(FT.Typography.caption)
                .foregroundStyle(FT.Palette.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .frame(height: 140)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.clear)
                .ftGlassRounded(cornerRadius: 20)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - Range picker

private struct RangePicker: View {
    @Binding var selection: TrendsSheet.Range

    var body: some View {
        GeometryReader { geo in
            let count = CGFloat(TrendsSheet.Range.allCases.count)
            let itemWidth = geo.size.width / count
            let index = CGFloat(TrendsSheet.Range.allCases.firstIndex(of: selection) ?? 0)

            FTGlassContainer {
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.clear)
                        .ftGlass(.rounded(14))
                        .ftGlassSelectionStroke(isSelected: false, shape: .rounded(14))

                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(.clear)
                        .ftGlassRounded(cornerRadius: 11, tint: FT.Palette.white.opacity(0.75))
                        .frame(width: itemWidth - 6, height: geo.size.height - 6)
                        .offset(x: index * itemWidth + 3, y: 0)
                        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: selection)

                    HStack(spacing: 0) {
                        ForEach(TrendsSheet.Range.allCases) { option in
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                                selection = option
                            }) {
                                Text(NSLocalizedString(option.labelKey, comment: ""))
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(selection == option ? FT.Palette.black : FT.Palette.textSecondary)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .frame(height: 40)
    }
}

// MARK: - Weekly bars (mock chart)

private struct WeeklyBarsChart: View {
    private let values: [CGFloat] = [0.35, 0.55, 0.42, 0.78, 0.62, 0.88, 0.5]

    var body: some View {
        Canvas { ctx, size in
            let count = CGFloat(values.count)
            let spacing: CGFloat = 10
            let barWidth = (size.width - spacing * (count - 1)) / count
            for (i, v) in values.enumerated() {
                let x = CGFloat(i) * (barWidth + spacing)
                let h = max(6, size.height * v)
                let rect = CGRect(x: x, y: size.height - h, width: barWidth, height: h)
                let path = Path(roundedRect: rect, cornerRadius: 4)
                ctx.fill(path, with: .color(FT.Palette.brandRail.opacity(0.85)))
            }
        }
    }
}
