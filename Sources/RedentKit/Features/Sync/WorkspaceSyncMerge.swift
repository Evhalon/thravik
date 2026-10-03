import Foundation

public enum WorkspaceSyncMerge {
    public static func apply(local: BrowserSession, snapshot: WorkspaceSyncSnapshot) -> WorkspaceSyncApplication {
        guard let catalog = snapshot.catalog, catalog.schemaVersion == SyncSpaceCatalog.schemaVersion else {
            return WorkspaceSyncApplication(session: local, remoteTabs: remoteTabs(local: local, snapshot: snapshot))
        }
        let relocated = relocating(local.tabs, spaces: local.spaces, retired: catalog.retiredSpaceIDs)
        let tabs = appendingPins(relocated.tabs, catalog: catalog)
        let spaces = orderedSpaces(local: relocated.spaces, catalog: catalog)
        var session = BrowserSession(tabs: tabs, selectedTabID: local.selectedTabID, spaces: spaces,
                                     selectedSpaceID: local.selectedSpaceID)
        session.profile = catalog.profile ?? local.profile
        session.groups = mergedGroups(local: local.groups, catalog: catalog, session: session)
        session.splitLayout = local.splitLayout
        session.splitLayout.validate(against: Set(session.tabs.map(\.id)))
        assignGroups(&session)
        return WorkspaceSyncApplication(session: session, remoteTabs: remoteTabs(local: session, snapshot: snapshot))
    }

    private static func relocating(_ tabs: [TabSnapshot], spaces: [BrowserSpace], retired: [UUID])
        -> (tabs: [TabSnapshot], spaces: [BrowserSpace]) {
        let retiredIDs = Set(retired)
        let kept = spaces.filter { !retiredIDs.contains($0.id) }
        guard kept.count < spaces.count, let fallback = kept.first?.id else { return (tabs, spaces) }
        let moved = tabs.map { tab in
            guard let spaceID = tab.spaceID, retiredIDs.contains(spaceID) else { return tab }
            var copy = tab
            copy.spaceID = fallback
            return copy
        }
        return (moved, kept)
    }

    private static func appendingPins(_ tabs: [TabSnapshot], catalog: SyncSpaceCatalog) -> [TabSnapshot] {
        var result = tabs
        let known = Set(tabs.map(\.id))
        for pin in catalog.pins where pin.isPinned && !known.contains(pin.id) {
            guard let tab = pinnedTab(pin) else { continue }
            result.append(tab)
        }
        return result
    }

    private static func pinnedTab(_ pin: SyncTabSnapshot) -> TabSnapshot? {
        guard let url = pin.url ?? pin.pinnedURL else { return nil }
        var tab = TabSnapshot(id: pin.id, url: url, title: pin.title, isPinned: true, spaceID: pin.spaceID)
        tab.pinnedURL = pin.pinnedURL ?? url
        tab.customTitle = pin.customTitle
        tab.customEmoji = TabCustomEmoji.validated(pin.customEmoji)
        tab.groupID = pin.groupID
        if pin.zoom > 0 { tab.zoom = pin.zoom }
        return tab
    }

    private static func orderedSpaces(local: [BrowserSpace], catalog: SyncSpaceCatalog) -> [BrowserSpace] {
        let retired = Set(catalog.retiredSpaceIDs)
        let localByID = Dictionary(local.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        var ordered: [BrowserSpace] = []
        for remote in catalog.spaces.sorted(by: { $0.order < $1.order }) where !retired.contains(remote.id) {
            ordered.append(adopting(remote, existing: localByID[remote.id]))
        }
        let seen = Set(ordered.map(\.id))
        for space in local where !seen.contains(space.id) && !retired.contains(space.id) { ordered.append(space) }
        return ordered.isEmpty ? local : ordered
    }

    private static func adopting(_ remote: SyncSpace, existing: BrowserSpace?) -> BrowserSpace {
        var space = existing ?? BrowserSpace(id: remote.id, name: remote.name)
        space.name = remote.name
        space.icon = remote.icon
        space.colorToken = remote.colorToken
        return space
    }

    private static func mergedGroups(local: [BrowserGroup], catalog: SyncSpaceCatalog,
                                     session: BrowserSession) -> [BrowserGroup] {
        let retiredSpaces = Set(catalog.retiredSpaceIDs)
        let retiredGroups = Set(catalog.retiredGroupIDs)
        var groups = local.filter { !retiredGroups.contains($0.id) && !retiredSpaces.contains($0.spaceID) }
        for remote in catalog.groups where !retiredGroups.contains(remote.id) && !retiredSpaces.contains(remote.spaceID) {
            guard session.spaces.contains(where: { $0.id == remote.spaceID }) else { continue }
            upsert(&groups, remote, tabs: session.tabs)
        }
        return groups.map { group in
            var copy = group
            copy.tabIDs = copy.tabIDs.filter { id in session.tabs.contains { $0.id == id } }
            return copy
        }
    }

    private static func upsert(_ groups: inout [BrowserGroup], _ remote: BrowserGroup, tabs: [TabSnapshot]) {
        let members = remote.tabIDs.filter { id in tabs.contains { $0.id == id } }
        guard let index = groups.firstIndex(where: { $0.id == remote.id }) else {
            var created = remote
            created.tabIDs = members
            groups.append(created)
            return
        }
        groups[index].name = remote.name
        groups[index].colorToken = remote.colorToken
        groups[index].isNameAutomatic = remote.isNameAutomatic
        for id in members where !groups[index].tabIDs.contains(id) { groups[index].tabIDs.append(id) }
    }

    private static func assignGroups(_ session: inout BrowserSession) {
        let groupIDs = Set(session.groups.map(\.id))
        session.tabs = session.tabs.map { tab in
            var copy = tab
            if let groupID = copy.groupID, !groupIDs.contains(groupID) { copy.groupID = nil }
            return copy
        }
        session.spaces = session.spaces.map { space in
            var copy = space
            copy.groupIDs = session.groups.filter { $0.spaceID == space.id }.map(\.id)
            return copy
        }
    }

    private static func remoteTabs(local: BrowserSession, snapshot: WorkspaceSyncSnapshot) -> [RemoteSyncedTab] {
        let known = Set(local.tabs.map(\.id))
        return snapshot.deviceTabs.flatMap { device -> [RemoteSyncedTab] in
            guard device.deviceID != snapshot.localDeviceID, device.schemaVersion == SyncDeviceTabs.schemaVersion
            else { return [] }
            return device.tabs.compactMap { tab in listed(tab, deviceID: device.deviceID, known: known) }
        }
    }

    private static func listed(_ tab: SyncTabSnapshot, deviceID: UUID, known: Set<UUID>) -> RemoteSyncedTab? {
        guard !tab.isPinned, !known.contains(tab.id), let url = tab.url else { return nil }
        let host = Origin(url: url)?.displayHost
        let title = tab.customTitle ?? (tab.title.isEmpty ? (host ?? "Tab") : tab.title)
        return RemoteSyncedTab(id: tab.id, deviceID: deviceID, title: title, url: url)
    }
}
