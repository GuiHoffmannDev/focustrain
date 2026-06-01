import SwiftUI

/// Top-down view of the wagon: a rounded body with a curved nose at the top,
/// 7 rows of seats split into two pairs by a central aisle. Row labels mirror
/// on both sides like a real cabin map.
struct WagonView: View {
    let layout: WagonLayout
    let selectedSeat: String?
    let usedSeats: Set<String>
    let onSelect: (String) -> Void

    private let noseHeight: CGFloat = 64
    private let seatSpacing: CGFloat = 10
    private let aisleWidth: CGFloat = 28
    private let rowVerticalSpacing: CGFloat = 12

    var body: some View {
        ZStack(alignment: .top) {
            wagonShell

            VStack(spacing: rowVerticalSpacing) {
                Color.clear.frame(height: noseHeight - 12) // breathing room under the nose

                ForEach(Array(layout.rows), id: \.self) { row in
                    rowView(row)
                }

                Color.clear.frame(height: 8)
            }
            .padding(.horizontal, 18)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Shell

    private var wagonShell: some View {
        WagonShape(noseHeight: noseHeight)
            .stroke(FT.Palette.textMuted.opacity(0.35), lineWidth: 1.5)
            .background(
                WagonShape(noseHeight: noseHeight)
                    .fill(FT.Palette.bgElevated.opacity(0.25))
            )
            .overlay(aisleGuide, alignment: .top)
    }

    /// Faint dashed line down the center to suggest the aisle.
    private var aisleGuide: some View {
        GeometryReader { proxy in
            Path { path in
                let x = proxy.size.width / 2
                path.move(to: CGPoint(x: x, y: noseHeight + 4))
                path.addLine(to: CGPoint(x: x, y: proxy.size.height - 12))
            }
            .stroke(
                FT.Palette.textMuted.opacity(0.25),
                style: StrokeStyle(lineWidth: 1, dash: [2, 6])
            )
        }
        .allowsHitTesting(false)
    }

    // MARK: - Rows

    private func rowView(_ row: Int) -> some View {
        HStack(spacing: 0) {
            rowLabel(row)

            HStack(spacing: seatSpacing) {
                ForEach(layout.leftColumns, id: \.self) { column in
                    seatTile(row: row, column: column)
                }
            }

            Spacer().frame(width: aisleWidth)

            HStack(spacing: seatSpacing) {
                ForEach(layout.rightColumns, id: \.self) { column in
                    seatTile(row: row, column: column)
                }
            }

            rowLabel(row)
        }
        .frame(maxWidth: .infinity)
    }

    private func rowLabel(_ row: Int) -> some View {
        Text(WagonLayout.rowLabel(row))
            .font(.system(size: 10, weight: .semibold, design: .monospaced))
            .foregroundStyle(FT.Palette.textMuted)
            .frame(width: 22)
    }

    private func seatTile(row: Int, column: String) -> some View {
        let code = WagonLayout.seatCode(row: row, column: column)
        let state: SeatTile.State = {
            if selectedSeat == code { return .selected }
            if usedSeats.contains(code) { return .previouslyUsed }
            return .available
        }()
        return SeatTile(code: code, state: state) {
            onSelect(code)
        }
    }
}

/// Curved-nose wagon outline. The top edge is a single arc; the body is a
/// rounded rectangle sharing the same horizontal extents.
private struct WagonShape: Shape {
    let noseHeight: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cornerRadius: CGFloat = 28
        let bodyTop = rect.minY + noseHeight
        let leftX = rect.minX
        let rightX = rect.maxX

        // Start at the bottom-left, just above the corner.
        path.move(to: CGPoint(x: leftX, y: rect.maxY - cornerRadius))

        // Left side up to the start of the nose curve.
        path.addLine(to: CGPoint(x: leftX, y: bodyTop))

        // Nose arc (quadratic curve peaking at the top center).
        path.addQuadCurve(
            to: CGPoint(x: rightX, y: bodyTop),
            control: CGPoint(x: rect.midX, y: rect.minY - noseHeight * 0.15)
        )

        // Right side down to the bottom-right corner.
        path.addLine(to: CGPoint(x: rightX, y: rect.maxY - cornerRadius))

        // Bottom-right corner.
        path.addQuadCurve(
            to: CGPoint(x: rightX - cornerRadius, y: rect.maxY),
            control: CGPoint(x: rightX, y: rect.maxY)
        )

        // Bottom edge.
        path.addLine(to: CGPoint(x: leftX + cornerRadius, y: rect.maxY))

        // Bottom-left corner.
        path.addQuadCurve(
            to: CGPoint(x: leftX, y: rect.maxY - cornerRadius),
            control: CGPoint(x: leftX, y: rect.maxY)
        )

        return path
    }
}