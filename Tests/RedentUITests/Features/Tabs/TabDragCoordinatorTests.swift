import Foundation
import Testing
@testable import RedentUI

@MainActor
@Suite struct TabDragCoordinatorTests {
    private let first = UUID()
    private let second = UUID()
    private let loose = UUID()

    private func frame(_ index: Int) -> CGRect {
        CGRect(x: 0, y: CGFloat(index) * 30, width: 200, height: 30)
    }

    /// An automatic cluster is keyed by its first member, so its header and
    /// that tab share an id; neither may overwrite the other.
    private func expandedCluster() -> TabDragCoordinator {
        let drag = TabDragCoordinator(axis: .vertical)
        drag.track(.tab(first), drawing: [first], frame: frame(1))
        drag.track(.header(first), drawing: [], frame: frame(0))
        drag.track(.tab(second), drawing: [second], frame: frame(2))
        drag.track(.tab(loose), drawing: [loose], frame: frame(3))
        return drag
    }

    @Test func firstMemberSharingTheHeaderIDStillMoves() {
        let drag = expandedCluster()
        drag.follow(first, translation: CGSize(width: 0, height: 80))
        drag.refreshSlot(pointer: CGPoint(x: 10, y: 115))
        #expect(drag.drop() == [second, loose, first])
    }

    @Test func headerShiftsAsTheLiftedTabPassesIt() {
        let drag = expandedCluster()
        drag.follow(loose, translation: CGSize(width: 0, height: -100))
        drag.refreshSlot(pointer: CGPoint(x: 10, y: 5))
        #expect(drag.offset(for: .header(first)).height == 30)
    }

    @Test func foldingAClusterKeepsItsHeaderTracked() {
        let drag = TabDragCoordinator(axis: .vertical)
        drag.track(.header(first), drawing: [first, second], frame: frame(0))
        drag.track(.tab(loose), drawing: [loose], frame: frame(1))
        drag.forget(.tab(first))
        drag.follow(loose, translation: CGSize(width: 0, height: -40))
        drag.refreshSlot(pointer: CGPoint(x: 10, y: 5))
        #expect(drag.drop() == [loose, first, second])
    }

    /// Joining a group redraws the tab in a new row; the old row vanishing
    /// afterwards must not erase the new one, or the tab can never lift again.
    @Test func tabRedrawnInAGroupStillLiftsAfterTheOldRowGoes() {
        let drag = TabDragCoordinator(axis: .vertical)
        let oldRow = UUID()
        let newRow = UUID()
        drag.track(.tab(loose), owner: oldRow, drawing: [loose], frame: frame(0))
        drag.track(.tab(first), drawing: [first], frame: frame(1))
        drag.track(.tab(loose), owner: newRow, drawing: [loose], frame: frame(2))
        drag.forget(.tab(loose), owner: oldRow)

        drag.follow(loose, translation: CGSize(width: 0, height: -60))
        #expect(drag.isDragging)
    }
}
