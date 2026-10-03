import Foundation

public struct SyncWorkspaceSnapshot: Codable, Sendable, Equatable {
    public let schemaVersion: Int
    public let deviceID: UUID
    public let spaces: [BrowserSpace]
    public let tabs: [SyncTabSnapshot]
    public let groups: [BrowserGroup]

    public init(session: BrowserSession, deviceID: UUID) {
        schemaVersion = 1
        self.deviceID = deviceID
        tabs = session.tabs.compactMap { SyncTabSnapshot(tab: $0) }
        let ids = Set(tabs.map(\.id))
        groups = session.groups.map { group in
            var cleaned = group
            cleaned.tabIDs = group.tabIDs.filter { ids.contains($0) }
            return cleaned
        }
        let groupIDs = Set(groups.map(\.id))
        spaces = session.spaces.map { space in
            var cleaned = space
            cleaned.tabIDs = space.tabIDs.filter { ids.contains($0) }
            cleaned.groupIDs = space.groupIDs.filter { groupIDs.contains($0) }
            cleaned.selectedTabID = nil
            return cleaned
        }
    }
}
