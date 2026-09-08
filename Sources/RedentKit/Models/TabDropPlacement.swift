import Foundation

/// Where a tab dragged onto another row lands in the controller's order.
/// Pure index arithmetic so the drag gesture in the strips stays dumb.
public enum TabDropPlacement {
    public struct Move: Equatable, Sendable {
        public let from: Int
        public let to: Int

        public var offsets: IndexSet { IndexSet(integer: from) }
    }

    /// - Parameter ids: visible tabs, in the order the controller holds them.
    /// - Returns: nil when the drag changes nothing or names an unknown tab.
    public static func move(_ sourceID: UUID, onto targetID: UUID, in ids: [UUID]) -> Move? {
        guard sourceID != targetID,
              let from = ids.firstIndex(of: sourceID),
              let to = ids.firstIndex(of: targetID) else { return nil }
        // `move(fromOffsets:toOffset:)` inserts *before* `toOffset`, and the
        // source is still counted when it sits above the target.
        return Move(from: from, to: to > from ? to + 1 : to)
    }
}
