import SwiftUI

/// Upper portion of the boarding pass: IATA headers, cities, duration,
/// and the 2×2 metadata grid (Seat / Boarding / Distance / Date).
struct TicketBodyView: View {
    let display: BoardingPassDisplay

    var body: some View {
        VStack(spacing: 18) {
            header
            route
            metadataGrid
        }
        .padding(.horizontal, 22)
        .padding(.top, 24)
        .padding(.bottom, 18)
    }

    private var header: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "airplane")
                    .font(.system(size: 12, weight: .bold))
                Text("BOARDING PASS")
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    .tracking(1.4)
            }
            .foregroundStyle(FT.Palette.Ticket.inkMuted)
            Spacer()
            Text(display.code)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .tracking(0.8)
                .foregroundStyle(FT.Palette.Ticket.inkMuted)
        }
    }

    private var route: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(display.fromCode)
                    .font(.system(size: 42, weight: .black, design: .default))
                    .foregroundStyle(FT.Palette.Ticket.ink)
                Text(display.fromCity.uppercased())
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .tracking(0.6)
                    .foregroundStyle(FT.Palette.Ticket.inkMuted)
                    .lineLimit(1)
            }
            VStack(spacing: 4) {
                Image(systemName: "airplane")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(FT.Palette.Ticket.ink.opacity(0.85))
                Text(display.durationLabel)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .tracking(0.4)
                    .foregroundStyle(FT.Palette.Ticket.inkStrong)
            }
            .frame(maxWidth: .infinity)
            VStack(alignment: .trailing, spacing: 4) {
                Text(display.toCode)
                    .font(.system(size: 42, weight: .black, design: .default))
                    .foregroundStyle(FT.Palette.Ticket.ink)
                Text(display.toCity.uppercased())
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .tracking(0.6)
                    .foregroundStyle(FT.Palette.Ticket.inkMuted)
                    .lineLimit(1)
            }
        }
    }

    private var metadataGrid: some View {
        let columns = [GridItem(.flexible(), alignment: .leading),
                       GridItem(.flexible(), alignment: .leading)]
        return LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
            field("SEAT", display.seat)
            field("BOARDING", display.boardingLabel)
            field("DISTANCE", display.distanceLabel)
            field("DATE", display.dateLabel)
        }
        .padding(.top, 4)
    }

    private func field(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .tracking(0.8)
                .foregroundStyle(FT.Palette.Ticket.inkFaint)
            Text(value)
                .font(FT.Typography.ticketField)
                .foregroundStyle(FT.Palette.Ticket.ink)
        }
    }
}
