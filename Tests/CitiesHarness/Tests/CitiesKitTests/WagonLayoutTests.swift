import Testing
@testable import CitiesKit

@Suite struct WagonLayoutTests {
    @Test func standardLayoutHasTwentyRows() {
        #expect(WagonLayout.standard.rows == 1...20)
    }

    @Test func seatCodesAreZeroPadded() {
        #expect(WagonLayout.seatCode(row: 1, column: "A") == "01A")
        #expect(WagonLayout.seatCode(row: 12, column: "C") == "12C")
        #expect(WagonLayout.seatCode(row: 20, column: "F") == "20F")
    }

    @Test func legacySevenRowCodesRemainValid() {
        // Journeys recorded before the 20-row carriage used rows 01–07; their
        // codes must still exist in the new layout so SeatHistory tinting works.
        let layout = WagonLayout.standard
        let all = Set(layout.rows.flatMap { row in
            layout.allColumns.map { WagonLayout.seatCode(row: row, column: $0) }
        })
        for row in 1...7 {
            for column in ["A", "C", "D", "F"] {
                #expect(all.contains(WagonLayout.seatCode(row: row, column: column)))
            }
        }
    }
}
