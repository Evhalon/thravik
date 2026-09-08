import Foundation
import Testing
@testable import RedentKit

@Suite struct TabDropPlacementTests {
    private let ids = (0..<4).map { _ in UUID() }

    @Test func draggingDownInsertsAfterTheTarget() {
        let move = TabDropPlacement.move(ids[0], onto: ids[2], in: ids)
        #expect(move == TabDropPlacement.Move(from: 0, to: 3))
    }

    @Test func draggingUpInsertsBeforeTheTarget() {
        let move = TabDropPlacement.move(ids[3], onto: ids[1], in: ids)
        #expect(move == TabDropPlacement.Move(from: 3, to: 1))
    }

    @Test func droppingOnItselfDoesNothing() {
        #expect(TabDropPlacement.move(ids[1], onto: ids[1], in: ids) == nil)
    }

    @Test func unknownTabIsRejected() {
        #expect(TabDropPlacement.move(UUID(), onto: ids[1], in: ids) == nil)
        #expect(TabDropPlacement.move(ids[1], onto: UUID(), in: ids) == nil)
    }

    @Test func neighbourSwapKeepsBothTabs() throws {
        let move = try #require(TabDropPlacement.move(ids[1], onto: ids[2], in: ids))
        #expect(applying(move, to: ids) == [ids[0], ids[2], ids[1], ids[3]])
    }

    @Test func draggingToTheEndPutsTheTabLast() throws {
        let move = try #require(TabDropPlacement.move(ids[0], onto: ids[3], in: ids))
        #expect(applying(move, to: ids) == [ids[1], ids[2], ids[3], ids[0]])
    }

    /// Mirrors `RangeReplaceableCollection.move(fromOffsets:toOffset:)`, which
    /// lives in SwiftUI and so cannot be reached from this target.
    private func applying(_ move: TabDropPlacement.Move, to order: [UUID]) -> [UUID] {
        var result = order
        let moved = result.remove(at: move.from)
        result.insert(moved, at: move.to > move.from ? move.to - 1 : move.to)
        return result
    }
}
