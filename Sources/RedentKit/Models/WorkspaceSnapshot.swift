import Foundation

public struct WorkspaceSnapshot: Codable, Sendable, Equatable {
    public static let currentSchemaVersion = 2

    public var schemaVersion: Int
    public var revision: Int
    public var spaces: [BrowserSpace]
    public var groups: [BrowserGroup]
    public var tabs: [TabSnapshot]
    public var selectedSpaceID: UUID?
    public var selectedTabID: UUID?
    public var splitLayout: SplitLayout

    private enum CodingKeys: String, CodingKey {
        case schemaVersion, revision, spaces, groups, tabs
        case selectedSpaceID, selectedTabID, splitLayout
    }

    public init(session: BrowserSession, revision: Int = 0) {
        let durable = Self.durableSession(session)
        self.schemaVersion = Self.currentSchemaVersion
        self.revision = max(revision, 0)
        self.spaces = durable.spaces
        self.groups = durable.groups
        self.tabs = durable.tabs
        self.selectedSpaceID = durable.selectedSpaceID
        self.selectedTabID = durable.selectedTabID
        self.splitLayout = durable.splitLayout
    }

    public var session: BrowserSession {
        var result = BrowserSession(
            tabs: tabs,
            selectedTabID: selectedTabID,
            spaces: spaces,
            selectedSpaceID: selectedSpaceID
        )
        result.groups = groups
        result.splitLayout = splitLayout
        result.splitLayout.validate(against: Set(tabs.map(\.id)))
        return result
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.schemaVersion = try values.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        self.revision = try values.decodeIfPresent(Int.self, forKey: .revision) ?? 0
        self.spaces = try values.decodeIfPresent([BrowserSpace].self, forKey: .spaces) ?? BrowserSpace.starterSpaces
        self.groups = try values.decodeIfPresent([BrowserGroup].self, forKey: .groups) ?? []
        self.tabs = try values.decodeIfPresent([TabSnapshot].self, forKey: .tabs) ?? []
        self.selectedSpaceID = try values.decodeIfPresent(UUID.self, forKey: .selectedSpaceID)
        self.selectedTabID = try values.decodeIfPresent(UUID.self, forKey: .selectedTabID)
        self.splitLayout = try values.decodeIfPresent(SplitLayout.self, forKey: .splitLayout) ?? SplitLayout()
    }

    private static func durableSession(_ session: BrowserSession) -> BrowserSession {
        let tabs = session.tabs.filter { !$0.isTemporary }
        let tabIDs = Set(tabs.map(\.id))
        var durable = BrowserSession(
            tabs: tabs,
            selectedTabID: session.selectedTabID.flatMap { tabIDs.contains($0) ? $0 : nil },
            spaces: session.spaces,
            selectedSpaceID: session.selectedSpaceID
        )
        durable.groups = session.groups.map { group in
            var result = group
            result.tabIDs = group.tabIDs.filter { tabIDs.contains($0) }
            return result
        }
        durable.splitLayout = session.splitLayout
        durable.splitLayout.validate(against: tabIDs)
        return durable
    }
}
