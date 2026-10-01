import Observation
import RedentKit
import SwiftUI

/// Where a tab dragged out of the sidebar list is pinned on release: the
/// pinned area above the list, at the cell under the pointer.
///
/// The area and the rows live in different coordinate spaces — the rows' is
/// inside the scroll view — so both sides meet in `.global`.
@MainActor
@Observable
final class PinDropTarget {
    private struct Area {
        let frame: CGRect
        let pins: Int
    }

    /// The cell a release would pin into, so the tiles can open a gap there.
    /// Nil while no dragged tab hovers the pinned area.
    private(set) var slot: Int?
    /// Keyed by the reporting view, not the Space: the pager rebuilds pages as
    /// it turns, and an old page's `onDisappear` can land after the new one
    /// reported the same Space.
    @ObservationIgnored private var areas: [UUID: Area] = [:]

    var isTargeted: Bool { slot != nil }

    /// - Parameter pins: the tiles drawn there, not counting an open gap.
    func track(_ owner: UUID, frame: CGRect, pins: Int) {
        areas[owner] = Area(frame: frame, pins: pins)
    }

    func forget(_ owner: UUID) { areas.removeValue(forKey: owner) }

    /// Returns the cell a release at `pointer`, in `.global`, would pin into.
    @discardableResult
    func refresh(pointer: CGPoint) -> Int? {
        let next = areas.values.lazy.compactMap { Self.slot(in: $0, at: pointer) }.first
        if next != slot { slot = next }
        return next
    }

    func end() { slot = nil }

    private static func slot(in area: Area, at pointer: CGPoint) -> Int? {
        // A little slack above and below: the tiles are short targets.
        guard area.frame.insetBy(dx: 0, dy: -6).contains(pointer) else { return nil }
        let cells = area.pins + 1
        return PinnedTileGeometry(count: cells, width: area.frame.width).slot(
            atX: pointer.x - area.frame.minX, y: pointer.y - area.frame.minY, count: cells
        )
    }
}
