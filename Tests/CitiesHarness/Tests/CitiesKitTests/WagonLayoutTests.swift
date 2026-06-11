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
        // Expected codes are hardcoded (not re-derived from the layout) so a
        // regression in the row range or columns actually fails this test.
        let layout = WagonLayout.standard
        let all = Set(layout.rows.flatMap { row in
            layout.allColumns.map { WagonLayout.seatCode(row: row, column: $0) }
        })
        let legacyCodes = ["01A", "01C", "01D", "01F", "07A", "07C", "07D", "07F"]
        for code in legacyCodes {
            #expect(all.contains(code))
        }
    }
}
