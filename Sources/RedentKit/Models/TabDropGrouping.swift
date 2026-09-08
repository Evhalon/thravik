import Foundation

/// Cluster membership after a drag.
///
/// The sidebar draws clusters from membership, not from order, so a tab that
/// is dropped between two rows of a cluster has to join it and one dropped
/// outside has to leave — otherwise the outline re-nests the tab and the drop
/// looks like it snapped back.
public enum TabDropGrouping: Sendable {
    public enum Outcome: Equatable, Sendable {
        case keep
        case leave
        case join(UUID)
    }

    /// - Parameter order: the visual order right after the drop.
    public static func outcome(
        moved: UUID,
        order: [UUID],
        tabs: [TabSnapshot],
        groups: [BrowserGroup]
    ) -> Outcome {
        guard let tab = tabs.first(where: { $0.id == moved }), !tab.isPinned,
              let index = order.firstIndex(of: moved) else { return .keep }
        let current = tab.groupID ?? tab.parentTabID
        let host = enclosingCluster(at: index, order: order, tabs: tabs)
        guard host != current else { return .keep }
        guard let host else { return departed(current, at: index, order: order, tabs: tabs) }
        // Only a named group can take a new member; an opener-based cluster
        // has no id to assign, so such a drop stays a pure reorder.
        guard groups.contains(where: { $0.id == host }) else { return .keep }
        return .join(host)
    }

    /// The last row of a cluster and the first row after it look the same in a
    /// flat order, so an unclustered tab stays out and a member stays in as
    /// long as the row above it is still one of its own.
    private static func departed(
        _ current: UUID?,
        at index: Int,
        order: [UUID],
        tabs: [TabSnapshot]
    ) -> Outcome {
        guard let current else { return .keep }
        guard index > 0, let above = tabs.first(where: { $0.id == order[index - 1] }),
              clusterKeys(above).contains(current) else { return .leave }
        return .keep
    }

    /// The cluster both neighbours belong to, if they share one.
    private static func enclosingCluster(at index: Int, order: [UUID], tabs: [TabSnapshot]) -> UUID? {
        guard index > 0, index + 1 < order.count,
              let above = tabs.first(where: { $0.id == order[index - 1] }),
              let below = tabs.first(where: { $0.id == order[index + 1] }) else { return nil }
        let belowKeys = clusterKeys(below)
        return clusterKeys(above).first { belowKeys.contains($0) }
    }

    /// Clusters a neighbour speaks for: its group, its opener, or itself when
    /// it is the opener a related cluster is named after. Group first, so a
    /// named group wins over the opener that seeded it.
    private static func clusterKeys(_ tab: TabSnapshot) -> [UUID] {
        [tab.groupID, tab.parentTabID, tab.id].compactMap { $0 }
    }
}
