import Foundation
import Testing
@testable import RedentKit

@Suite struct TabDropPlacementTests {
    private let ids = (0..<4).map { _ in UUID() }

    private var rows: [[UUID]] { ids.map { [$0] } }

    @Test func slotAfterTwoOthersMovesTheTabDown() {
        #expect(
            TabDropPlacement.reordered(ids[0], afterCount: 2, in: rows) == [ids[1], ids[2], ids[0], ids[3]]
        )
    }

    @Test func slotAtOriginDoesNothing() {
        #expect(TabDropPlacement.reordered(ids[1], afterCount: 1, in: rows) == nil)
    }

    @Test func slotAtStartMovesTheTabUp() {
        #expect(
            TabDropPlacement.reordered(ids[3], afterCount: 0, in: rows) == [ids[3], ids[0], ids[1], ids[2]]
        )
    }

    @Test func slotBeyondTheEndsIsClamped() {
        #expect(
            TabDropPlacement.reordered(ids[0], afterCount: 99, in: rows) == [ids[1], ids[2], ids[3], ids[0]]
        )
        #expect(
            TabDropPlacement.reordered(ids[2], afterCount: -5, in: rows) == [ids[2], ids[0], ids[1], ids[3]]
        )
    }

    @Test func aCollapsedClusterTravelsWhole() {
        let cluster = [ids[1], ids[2]]
        #expect(
            TabDropPlacement.reordered(ids[0], afterCount: 1, in: [[ids[0]], cluster, [ids[3]]])
                == [ids[1], ids[2], ids[0], ids[3]]
        )
    }

    @Test func unknownTabIsRejected() {
        #expect(TabDropPlacement.reordered(UUID(), afterCount: 1, in: rows) == nil)
    }

    /// A cluster row cannot be lifted, so a drag naming one is refused rather
    /// than silently dropping the members it stands for.
    @Test func aRowStandingForSeveralTabsCannotBeDragged() {
        #expect(TabDropPlacement.reordered(ids[0], afterCount: 1, in: [[ids[0], ids[1]], [ids[2]]]) == nil)
    }
}
