import Observation
import SwiftUI

/// Where a tab dragged out of the sidebar list is pinned on release: the empty
/// pinned area above the list.
///
/// The zone and the rows live in different coordinate spaces — the rows' is
/// inside the scroll view — so both sides meet in `.global`.
@MainActor
@Observable
final class PinDropTarget {
    /// True while a dragged tab hovers the zone, so it can light up.
    private(set) var isTargeted = false
    /// Keyed by the reporting view, not the Space: the pager rebuilds pages as
    /// it turns, and an old page's `onDisappear` can land after the new one
    /// reported the same Space.
    @ObservationIgnored private var frames: [UUID: CGRect] = [:]

    func track(_ owner: UUID, frame: CGRect) { frames[owner] = frame }

    func forget(_ owner: UUID) { frames.removeValue(forKey: owner) }

    /// Returns whether a release at `pointer`, in `.global`, would pin.
    @discardableResult
    func refresh(pointer: CGPoint) -> Bool {
        let over = frames.values.contains { $0.contains(pointer) }
        if over != isTargeted { isTargeted = over }
        return over
    }

    func end() { isTargeted = false }
}
