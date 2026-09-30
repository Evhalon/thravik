import Foundation

/// Automatic site clusters after a drag.
///
/// A site cluster has no id to join or leave, so a drop decides by
/// neighbourhood: landing beside a tab of the same site keeps the tab in, or
/// brings it back; landing anywhere else sets it apart.
public enum TabDropSiteGrouping: Sendable {
    /// - Parameter order: the visual order right after the drop.
    /// - Returns: the tab's new `standsApartFromSite`, or nil when it is unchanged.
    public static func apartness(moved: UUID, order: [UUID], tabs: [TabSnapshot]) -> Bool? {
        guard let tab = tabs.first(where: { $0.id == moved }), isClusterable(tab),
              let host = tab.origin?.displayHost,
              let index = order.firstIndex(of: moved) else { return nil }
        let kin = Set(tabs.filter { other in
            other.id != moved && other.spaceID == tab.spaceID && isClusterable(other)
                && !other.standsApartFromSite && other.origin?.displayHost == host
        }.map(\.id))
        guard !kin.isEmpty else { return nil }
        let neighbours = [index - 1, index + 1].filter(order.indices.contains).map { order[$0] }
        let apart = !neighbours.contains(where: kin.contains)
        return apart == tab.standsApartFromSite ? nil : apart
    }

    /// Only a tab that no group or opener claims can join a site cluster.
    private static func isClusterable(_ tab: TabSnapshot) -> Bool {
        !tab.isPinned && tab.groupID == nil && tab.parentTabID == nil
    }
}
