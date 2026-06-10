import SwiftUI

private struct TicketShape: Shape {
    var notchRadius: CGFloat = 12
    var notchY: CGFloat

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let r = FT.Layout.cardRadius

        p.move(to: CGPoint(x: r, y: 0))
        p.addLine(to: CGPoint(x: rect.maxX - r, y: 0))
        p.addArc(center: CGPoint(x: rect.maxX - r, y: r),
                 radius: r, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)

        p.addLine(to: CGPoint(x: rect.maxX, y: notchY - notchRadius))
        p.addArc(center: CGPoint(x: rect.maxX, y: notchY),
                 radius: notchRadius, startAngle: .degrees(-90), endAngle: .degrees(90), clockwise: true)

        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - r))
        p.addArc(center: CGPoint(x: rect.maxX - r, y: rect.maxY - r),
                 radius: r, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)

        p.addLine(to: CGPoint(x: r, y: rect.maxY))
        p.addArc(center: CGPoint(x: r, y: rect.maxY - r),
                 radius: r, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)

        p.addLine(to: CGPoint(x: 0, y: notchY + notchRadius))
        p.addArc(center: CGPoint(x: 0, y: notchY),
                 radius: notchRadius, startAngle: .degrees(90), endAngle: .degrees(-90), clockwise: true)

        p.addLine(to: CGPoint(x: 0, y: r))
        p.addArc(center: CGPoint(x: r, y: r),
                 radius: r, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)

        p.closeSubpath()
        return p
    }
}

struct TrainTicketCard: View {
    let fromCode: String
    let toCode: String
    let fromName: String
    let toName: String
    let scenarioTag: String
    let departLabel: String
    let durationLabel: String
    let ticketCode: String

    @State private var measuredHeight: CGFloat = 320

    var body: some View {
        GeometryReader { geo in
            let notchY = geo.size.height * 0.62

            ZStack {
                TicketShape(notchY: notchY)
                    .fill(FT.Palette.brandBrass)
                    .shadow(color: FT.Palette.brandBrass.opacity(0.35), radius: 18, y: 8)

                VStack(spacing: 0) {
                    topSection
                    Spacer(minLength: 12)
                    perforation
                        .padding(.vertical, 4)
                    bottomSection
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 20)
            }
        }
        .frame(height: 320)
    }

    private var topSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "tram.fill")
                        .font(.system(size: 13, weight: .bold))
                    Text("FOCUSTRAIN")
                        .font(.system(size: 12, weight: .heavy, design: .default))
                        .tracking(1.2)
                }
                .foregroundStyle(FT.Palette.white)
                Spacer()
                Text(scenarioTag.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .tracking(0.8)
                    .foregroundStyle(FT.Palette.ink.opacity(0.6))
            }

            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(fromCode)
                        .font(.system(size: 40, weight: .black))
                        .foregroundStyle(FT.Palette.ink)
                    Text(fromName)
                        .font(FT.Typography.caption)
                        .foregroundStyle(FT.Palette.ink.opacity(0.55))
                }
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(FT.Palette.white)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(toCode)
                        .font(.system(size: 40, weight: .black))
                        .foregroundStyle(FT.Palette.ink)
                    Text(toName)
                        .font(FT.Typography.caption)
                        .foregroundStyle(FT.Palette.ink.opacity(0.55))
                }
            }
        }
    }

    private var perforation: some View {
        GeometryReader { g in
            Path { p in
                p.move(to: CGPoint(x: 0, y: g.size.height / 2))
                p.addLine(to: CGPoint(x: g.size.width, y: g.size.height / 2))
            }
            .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
            .foregroundStyle(FT.Palette.ink.opacity(0.25))
        }
        .frame(height: 1)
    }

    private var bottomSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                field("DEPART", departLabel)
                field("DURATION", durationLabel)
                field("CODE", ticketCode)
            }
            Spacer()
            qrCode
        }
        .padding(.top, 8)
    }

    private func field(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .tracking(0.8)
                .foregroundStyle(FT.Palette.ink.opacity(0.5))
            Text(value)
                .font(FT.Typography.ticketField)
                .foregroundStyle(FT.Palette.ink)
        }
    }

    private var qrCode: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(FT.Palette.ink)
                .frame(width: 64, height: 64)
            Image(systemName: "qrcode")
                .font(.system(size: 50))
                .foregroundStyle(FT.Palette.surfaceLight)
        }
    }
}

#if DEBUG
private func _ticketPreview() -> some View {
    TrainTicketCard(
        fromCode: "SAO", toCode: "RIO",
        fromName: "São Paulo", toName: "Rio de Janeiro",
        scenarioTag: "Forest", departLabel: "12 Jun 2026",
        durationLabel: "60 min", ticketCode: "FT-7K2Q"
    )
    .padding()
    .background(FT.Palette.bgPrimary)
}

#Preview("Ticket — Dark") { _ticketPreview().preferredColorScheme(.dark) }
#Preview("Ticket — Light") { _ticketPreview().preferredColorScheme(.light) }
#endif
