import Foundation

/// Where a dragged tab lands once the pointer settles.
///
/// A row can stand for several tabs — a collapsed cluster draws one row and
/// carries all of its members — so a drop lands between whole rows and never
/// splits a cluster open.
public enum TabDropPlacement {
    /// - Parameters:
    ///   - rows: visible rows top to bottom, each listing the tabs it draws.
    ///   - slot: how many rows other than the dragged one sit before the pointer.
    /// - Returns: the flattened order, or nil when nothing actually moved.
    public static func reordered(_ sourceID: UUID, afterCount slot: Int, in rows: [[UUID]]) -> [UUID]? {
        guard rows.contains([sourceID]) else { return nil }
        let others = rows.filter { !$0.contains(sourceID) }
        let index = min(max(slot, 0), others.count)
        let next = others.prefix(index).flatMap { $0 } + [sourceID] + others.dropFirst(index).flatMap { $0 }
        return next == rows.flatMap { $0 } ? nil : next
    }
}
