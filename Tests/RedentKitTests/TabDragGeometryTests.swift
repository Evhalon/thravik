import Foundation
import Testing
@testable import RedentKit

@Suite struct TabDragGeometryTests {
    private let ids = (0..<4).map { _ in UUID() }

    @Test func slotCountsOthersBeforeThePointer() {
        let mids: [(UUID, CGFloat)] = [
            (ids[0], 10), (ids[1], 40), (ids[2], 70), (ids[3], 100)
        ]
        #expect(TabDragGeometry.slot(pointer: 55, mids: mids, lifted: ids[0]) == 1)
        #expect(TabDragGeometry.slot(pointer: 5, mids: mids, lifted: ids[2]) == 0)
        #expect(TabDragGeometry.slot(pointer: 120, mids: mids, lifted: ids[0]) == 3)
    }

    @Test func shiftingDownMovesPassedRowsUp() {
        let shifts = TabDragGeometry.shifts(
            ids: ids, lifted: ids[0], from: 0, slot: 2, span: 34
        )
        #expect(shifts[ids[1]] == -34)
        #expect(shifts[ids[2]] == -34)
        #expect(shifts[ids[3]] == nil)
        #expect(shifts[ids[0]] == nil)
    }

    @Test func shiftingUpMovesPassedRowsDown() {
        let shifts = TabDragGeometry.shifts(
            ids: ids, lifted: ids[3], from: 3, slot: 1, span: 34
        )
        #expect(shifts[ids[1]] == 34)
        #expect(shifts[ids[2]] == 34)
        #expect(shifts[ids[0]] == nil)
    }

    @Test func sameSlotProducesNoShift() {
        let shifts = TabDragGeometry.shifts(
            ids: ids, lifted: ids[1], from: 1, slot: 1, span: 34
        )
        #expect(shifts.isEmpty)
    }
}
