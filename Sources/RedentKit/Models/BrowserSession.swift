import Foundation

/// A browser window's durable workspace state.
public struct BrowserSession: Sendable, Codable, Equatable {
    public var tabs: [TabSnapshot]
    public var selectedTabID: UUID?
    public var spaces: [BrowserSpace]
    public var selectedSpaceID: UUID?
    public var containers: [BrowserContainer]
    public var groups: [BrowserGroup]
    /// Which tabs the window was showing side by side. Validated against the
    /// restored tabs, so a pane whose tab is gone does not come back empty.
    public var splitLayout = SplitLayout()

    public init(
        tabs: [TabSnapshot] = [],
        selectedTabID: UUID? = nil,
        spaces: [BrowserSpace] = BrowserSpace.starterSpaces,
        selectedSpaceID: UUID? = BrowserSpace.workID,
        containers: [BrowserContainer] = [.default]
    ) {
        let usableSpaces = spaces.isEmpty ? BrowserSpace.starterSpaces : spaces
        let activeSpace = selectedSpaceID.flatMap { id in usableSpaces.contains { $0.id == id } ? id : nil }
            ?? usableSpaces[0].id
        self.spaces = usableSpaces
        self.selectedSpaceID = activeSpace
        self.containers = Self.normalizedContainers(containers)
        self.groups = []
        let spaceIDs = Set(usableSpaces.map(\.id))
        let containerIDs = Set(self.containers.map(\.id))
        self.tabs = Self.droppingOrphanParents(tabs.map { tab in
            var normalized = tab
            normalized.spaceID = tab.spaceID.flatMap { spaceIDs.contains($0) ? $0 : nil } ?? activeSpace
            normalized.containerID = tab.containerID.flatMap { containerIDs.contains($0) ? $0 : nil }
                ?? BrowserContainer.defaultID
            return normalized
        })
        self.selectedTabID = selectedTabID.flatMap { id in
            self.tabs.first { $0.id == id && $0.spaceID == activeSpace }?.id
        } ?? self.tabs.first { $0.spaceID == activeSpace }?.id
        self.spaces = Self.reconcileSpaces(self.spaces, tabs: self.tabs)
    }

    private enum CodingKeys: String, CodingKey {
        case tabs, selectedTabID, spaces, selectedSpaceID, containers, groups, splitLayout
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            tabs: try values.decodeIfPresent([TabSnapshot].self, forKey: .tabs) ?? [],
            selectedTabID: try values.decodeIfPresent(UUID.self, forKey: .selectedTabID),
            spaces: try values.decodeIfPresent([BrowserSpace].self, forKey: .spaces) ?? BrowserSpace.starterSpaces,
            selectedSpaceID: try values.decodeIfPresent(UUID.self, forKey: .selectedSpaceID),
            containers: try values.decodeIfPresent([BrowserContainer].self, forKey: .containers) ?? [.default]
        )
        self.groups = (try values.decodeIfPresent([BrowserGroup].self, forKey: .groups) ?? []).filter { group in
            self.spaces.contains { space in space.id == group.spaceID }
        }
        self.groups = self.groups.map { group in
            var normalized = group
            normalized.tabIDs = normalized.tabIDs.filter { id in self.tabs.contains { $0.id == id } }
            return normalized
        }
        self.splitLayout = try values.decodeIfPresent(SplitLayout.self, forKey: .splitLayout) ?? SplitLayout()
        self.splitLayout.validate(against: Set(self.tabs.map(\.id)))
        let groupIDs = Set(self.groups.map(\.id))
        self.tabs = Self.droppingOrphanParents(self.tabs.map { tab in
            var normalized = tab
            if let groupID = normalized.groupID, !groupIDs.contains(groupID) { normalized.groupID = nil }
            return normalized
        })
    }

    private static func droppingOrphanParents(_ tabs: [TabSnapshot]) -> [TabSnapshot] {
        let ids = Set(tabs.map(\.id))
        return tabs.map { tab in
            var next = tab
            if let parent = next.parentTabID, !ids.contains(parent) { next.parentTabID = nil }
            return next
        }
    }

    private static func normalizedContainers(_ containers: [BrowserContainer]) -> [BrowserContainer] {
        var result = containers
        if !result.contains(where: { $0.id == BrowserContainer.defaultID }) { result.insert(.default, at: 0) }
        return result
    }

    private static func reconcileSpaces(_ spaces: [BrowserSpace], tabs: [TabSnapshot]) -> [BrowserSpace] {
        let tabIDs = Set(tabs.map(\.id))
        return spaces.map { space in
            var result = space
            result.tabIDs = tabs.filter { $0.spaceID == space.id }.map(\.id)
                .filter { tabIDs.contains($0) }
            let preferred = space.selectedTabID ?? tabs.first { $0.spaceID == space.id }?.id
            result.selectedTabID = preferred.flatMap { result.tabIDs.contains($0) ? $0 : nil }
                ?? result.tabIDs.first
            return result
        }
    }
}
