import SwiftUI

/// Preference key collecting each seat slot's bounds so the host view can
/// anchor the focus modal near the tapped seat (the anchor persists even while
/// the tile itself is hidden during the morph).
struct SeatBoundsKey: PreferenceKey {
    static let defaultValue: [String: Anchor<CGRect>] = [:]
    static func reduce(value: inout [String: Anchor<CGRect>],
                       nextValue: () -> [String: Anchor<CGRect>]) {
        value.merge(nextValue()) { $1 }
    }
}

/// Top-down passenger carriage: rounded-top body, 20 rows of seats split by a
/// central aisle — row numbers live in the aisle, column letters in a header
/// row — and a long rounded tail that closes the train at the bottom.
struct WagonView: View {
    let layout: WagonLayout
    let seatState: (String) -> SeatTile.State
    let hiddenSeat: String?          // slot kept empty while it morphs into the modal
    let namespace: Namespace.ID
    let onSelect: (String) -> Void

    private let seatSpacing: CGFloat = 12
    private let aisleWidth: CGFloat = 44
    private let rowVerticalSpacing: CGFloat = 14
    private let tailHeight: CGFloat = 110

    var body: some View {
        ZStack(alignment: .top) {
            CarriageShape(tailHeight: tailHeight)
                .fill(FT.Palette.bgElevated.opacity(0.25))
                .overlay(
                    CarriageShape(tailHeight: tailHeight)
                        .stroke(FT.Palette.textMuted.opacity(0.35), lineWidth: 1.5)
                )

            VStack(spacing: rowVerticalSpacing) {
                columnHeader
                    .padding(.top, 28)

                ForEach(Array(layout.rows), id: \.self) { row in
                    rowView(row)
                }

                Color.clear.frame(height: tailHeight - 24)
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Column header (A C | D F)

    private var columnHeader: some View {
        HStack(spacing: seatSpacing) {
            ForEach(layout.leftColumns, id: \.self) { letterLabel($0) }
            Color.clear.frame(width: aisleWidth, height: 1)
            ForEach(layout.rightColumns, id: \.self) { letterLabel($0) }
        }
    }

    private func letterLabel(_ letter: String) -> some View {
        Text(letter)
            .font(.system(size: 13, weight: .semibold, design: .monospaced))
            .foregroundStyle(FT.Palette.textMuted)
            .frame(width: SeatTile.size)
    }

    // MARK: - Rows

    private func rowView(_ row: Int) -> some View {
        HStack(spacing: seatSpacing) {
            ForEach(layout.leftColumns, id: \.self) { column in
                seatSlot(row: row, column: column)
            }

            Text(WagonLayout.rowLabel(row))
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(FT.Palette.textMuted)
                .frame(width: aisleWidth)

            ForEach(layout.rightColumns, id: \.self) { column in
                seatSlot(row: row, column: column)
            }
        }
    }

    private func seatSlot(row: Int, column: String) -> some View {
        let code = WagonLayout.seatCode(row: row, column: column)
        return Group {
            if hiddenSeat == code {
                Color.clear
            } else {
                SeatTile(code: code, state: seatState(code)) {
                    onSelect(code)
                }
                .matchedGeometryEffect(id: code, in: namespace)
            }
        }
        .frame(width: SeatTile.size, height: SeatTile.size)
        .anchorPreference(key: SeatBoundsKey.self, value: .bounds) { [code: $0] }
    }
}

/// Rounded-top carriage body with a long rounded tail (big U) at the bottom.
private struct CarriageShape: Shape {
    let tailHeight: CGFloat

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let topRadius: CGFloat = 36
        let tailTop = rect.maxY - tailHeight

        p.move(to: CGPoint(x: rect.minX, y: tailTop))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + topRadius))
        p.addQuadCurve(
            to: CGPoint(x: rect.minX + topRadius, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.minY)
        )
        p.addLine(to: CGPoint(x: rect.maxX - topRadius, y: rect.minY))
        p.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + topRadius),
            control: CGPoint(x: rect.maxX, y: rect.minY)
        )
        p.addLine(to: CGPoint(x: rect.maxX, y: tailTop))
        // Tail: one sweeping curve through the bottom center.
        p.addQuadCurve(
            to: CGPoint(x: rect.minX, y: tailTop),
            control: CGPoint(x: rect.midX, y: rect.maxY + tailHeight * 0.35)
        )
        p.closeSubpath()
        return p
    }
}
