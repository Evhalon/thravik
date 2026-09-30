import Foundation

/// Builds the Dia-style sidebar: pinned tabs, then related clusters, then the rest.
public struct SidebarOutline: Equatable, Sendable {
    public let nodes: [SidebarNode]

    /// Top-to-bottom tab ids as the sidebar draws them.
    public var tabIDs: [UUID] { nodes.flatMap(\.tabIDs) }

    /// The pinned tabs, which the sidebar draws as tiles above its list.
    public let pinnedIDs: [UUID]

    public init(tabs: [TabSnapshot], groups: [BrowserGroup], spaceID: UUID?) {
        nodes = Self.build(tabs: tabs, groups: groups, spaceID: spaceID)
        pinnedIDs = tabs.filter { $0.spaceID == spaceID && $0.isPinned }.map(\.id)
    }

    /// The rows under the tiles. A pinned tab in `drawnAsRows` — one a split
    /// is showing as its row — keeps its place in the list.
    public func listNodes(keeping drawnAsRows: [UUID]) -> [SidebarNode] {
        nodes.filter { node in
            guard case .tab(let id) = node, pinnedIDs.contains(id) else { return true }
            return drawnAsRows.contains(id)
        }
    }

    private static func build(tabs: [TabSnapshot], groups: [BrowserGroup], spaceID: UUID?) -> [SidebarNode] {
        let visible = tabs.filter { $0.spaceID == spaceID }
        let unpinned = visible.filter { !$0.isPinned }
        var nodes: [SidebarNode] = visible.filter(\.isPinned).map { .tab($0.id) }
        var emitted = Set<UUID>()
        let present = Set(unpinned.map(\.id))
        let hostGroups = automaticHostGroups(in: unpinned)
        for tab in unpinned {
            if emitted.contains(tab.id) { continue }
            if let groupID = tab.groupID {
                appendGroup(groupID, from: unpinned, groups: groups, into: &nodes, emitted: &emitted)
                continue
            }
            if let parentID = tab.parentTabID, present.contains(parentID) { continue }
            if !tab.standsApartFromSite, let host = tab.origin?.displayHost, let members = hostGroups[host] {
                appendHostGroup(host, members: members, into: &nodes, emitted: &emitted)
                continue
            }
            appendRelatedOrTab(tab, from: unpinned, into: &nodes, emitted: &emitted)
        }
        return nodes
    }

    private static func automaticHostGroups(in tabs: [TabSnapshot]) -> [String: [TabSnapshot]] {
        let candidates = tabs.filter { $0.groupID == nil && $0.parentTabID == nil && !$0.standsApartFromSite }
        let grouped = Dictionary(grouping: candidates) { $0.origin?.displayHost }
        return grouped.reduce(into: [:]) { result, entry in
            guard let host = entry.key, entry.value.count >= 2 else { return }
            result[host] = entry.value
        }
    }

    private static func appendHostGroup(
        _ host: String,
        members: [TabSnapshot],
        into nodes: inout [SidebarNode],
        emitted: inout Set<UUID>
    ) {
        guard let id = members.first?.id else { return }
        members.forEach { emitted.insert($0.id) }
        emit(.init(id: id, name: host, memberIDs: members.map(\.id), isNameAutomatic: true), into: &nodes)
    }

    private static func appendGroup(
        _ groupID: UUID,
        from tabs: [TabSnapshot],
        groups: [BrowserGroup],
        into nodes: inout [SidebarNode],
        emitted: inout Set<UUID>
    ) {
        guard !emitted.contains(groupID) else { return }
        let members = tabs.filter { $0.groupID == groupID }
        members.forEach { emitted.insert($0.id) }
        emitted.insert(groupID)
        let group = groups.first { $0.id == groupID }
        let name = group?.name ?? members.first?.displayTitle ?? "Group"
        let cluster = SidebarNode.Cluster(
            id: groupID, name: name, memberIDs: members.map(\.id), isNameAutomatic: group?.isNameAutomatic ?? true
        )
        emit(cluster, into: &nodes)
    }

    private static func appendRelatedOrTab(
        _ tab: TabSnapshot,
        from tabs: [TabSnapshot],
        into nodes: inout [SidebarNode],
        emitted: inout Set<UUID>
    ) {
        let children = tabs.filter { $0.parentTabID == tab.id && $0.groupID == nil }
        emitted.insert(tab.id)
        children.forEach { emitted.insert($0.id) }
        let name = tab.origin?.displayHost ?? tab.displayTitle
        let members = [tab.id] + children.map(\.id)
        emit(.init(id: tab.id, name: name, memberIDs: members, isNameAutomatic: true), into: &nodes)
    }

    /// A cluster holding a single tab is that tab with extra chrome, so it is
    /// drawn flat — a header above one row reads as a duplicate.
    private static func emit(_ cluster: SidebarNode.Cluster, into nodes: inout [SidebarNode]) {
        guard cluster.memberIDs.count >= 2 else {
            cluster.memberIDs.forEach { nodes.append(.tab($0)) }
            return
        }
        nodes.append(.cluster(cluster))
    }
}
