import Foundation

/// Static description of the carriage used in `SeatPickerView`.
/// Two pairs of columns (A C | D F) split by a central aisle, 20 rows.
struct WagonLayout {
    let rows: ClosedRange<Int>
    let leftColumns: [String]
    let rightColumns: [String]

    static let standard = WagonLayout(
        rows: 1...20,
        leftColumns: ["A", "C"],
        rightColumns: ["D", "F"]
    )

    var allColumns: [String] { leftColumns + rightColumns }

    /// `"01"`, `"02"`, ... — zero-padded so seat codes sort lexicographically.
    static func rowLabel(_ row: Int) -> String {
        String(format: "%02d", row)
    }

    /// `"01C"`, `"07F"`, ... — full seat code combining row + column.
    static func seatCode(row: Int, column: String) -> String {
        rowLabel(row) + column
    }
}