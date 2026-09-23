import Foundation

/// Where a tab sits so it lands inside its site's automatic group.
///
/// `SidebarOutline` draws a site group where its first tab sits and names the
/// cluster after that tab's id. A same-site tab placed ahead of the group
/// would drag the whole group up to itself under a new identity; placed after
/// the group's last tab, it simply joins the group where it already is.
public enum HostGroupPlacement: Sendable {
    /// The index just past the last tab of `host` in the Space, or nil when no
    /// tab there shares the host.
    public static func insertionIndex(forHost host: String?, spaceID: UUID?, in tabs: [TabSnapshot]) -> Int? {
        guard let host else { return nil }
        return tabs.lastIndex { joinsGroup($0, host: host, spaceID: spaceID) }.map { $0 + 1 }
    }

    /// The index, among the other tabs, that tab `id` moves to when it has come
    /// to sit ahead of its site's group; nil when it is already in place.
    public static func settledIndex(of id: UUID, in tabs: [TabSnapshot]) -> Int? {
        guard let index = tabs.firstIndex(where: { $0.id == id }) else { return nil }
        let tab = tabs[index]
        guard let host = tab.origin?.displayHost, joinsGroup(tab, host: host, spaceID: tab.spaceID) else { return nil }
        var others = tabs
        others.remove(at: index)
        let siblings = others.indices.filter { joinsGroup(others[$0], host: host, spaceID: tab.spaceID) }
        guard let first = siblings.first, let last = siblings.last, first >= index else { return nil }
        return last + 1
    }

    /// Mirrors the tabs `SidebarOutline` gathers into automatic site groups.
    private static func joinsGroup(_ tab: TabSnapshot, host: String, spaceID: UUID?) -> Bool {
        tab.spaceID == spaceID && !tab.isPinned && tab.groupID == nil && tab.parentTabID == nil
            && tab.origin?.displayHost == host
    }
}
