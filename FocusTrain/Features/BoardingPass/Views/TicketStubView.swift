import SwiftUI

/// Lower portion of the boarding pass: passenger line + a procedural barcode
/// whose bar widths are deterministic by `ticket.code` hash.
struct TicketStubView: View {
    let display: BoardingPassDisplay

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                stubField("PASSENGER", "FOCUS / GUEST")
                Spacer()
                stubField("FLIGHT", display.code)
            }
            barcode
                .frame(height: 56)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 22)
        .padding(.top, 18)
        .padding(.bottom, 22)
    }

    private func stubField(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .tracking(0.8)
                .foregroundStyle(Color(white: 0.5))
            Text(value)
                .font(FT.Typography.ticketField)
                .foregroundStyle(FT.Palette.white)
        }
    }

    private var barcode: some View {
        GeometryReader { g in
            let bars = Self.bars(for: display.code, width: g.size.width)
            HStack(alignment: .center, spacing: 0) {
                ForEach(Array(bars.enumerated()), id: \.offset) { _, bar in
                    Rectangle()
                        .fill(bar.fill ? FT.Palette.white : Color.clear)
                        .frame(width: bar.width)
                }
            }
            .frame(height: g.size.height)
        }
    }

    /// Build a barcode-like sequence of black/white bar widths from a hash
    /// of the ticket code. Total width is fixed so it fills the container.
    private static func bars(for code: String, width: CGFloat) -> [Bar] {
        var hash = UInt64(bitPattern: Int64(code.hashValue))
        if hash == 0 { hash = 0xC0FFEE }
        var bars: [Bar] = []
        var fill = true
        var total: CGFloat = 0
        let target = width
        while total < target {
            // 1..4pt bars, alternating
            let w = CGFloat((hash & 0b11) + 1)
            let actualW = min(w, target - total)
            bars.append(Bar(width: actualW, fill: fill))
            total += actualW
            fill.toggle()
            hash = (hash &* 6364136223846793005) &+ 1442695040888963407
        }
        return bars
    }

    private struct Bar {
        let width: CGFloat
        let fill: Bool
    }
}
