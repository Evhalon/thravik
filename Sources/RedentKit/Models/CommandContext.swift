import Foundation

public struct CommandTabContext: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let title: String
    public let url: URL?
    public let isPinned: Bool
    public let spaceID: UUID?
    public let spaceName: String?

    public struct Values: Hashable, Sendable {
        public var url: URL?
        public var isPinned: Bool
        public var spaceID: UUID?
        public var spaceName: String?

        public init(url: URL? = nil, isPinned: Bool = false, spaceID: UUID? = nil, spaceName: String? = nil) {
            self.url = url
            self.isPinned = isPinned
            self.spaceID = spaceID
            self.spaceName = spaceName
        }
    }

    public init(id: UUID, title: String, values: Values = .init()) {
        self.id = id
        self.title = title
        self.url = values.url
        self.isPinned = values.isPinned
        self.spaceID = values.spaceID
        self.spaceName = values.spaceName
    }
}

public struct CommandSpaceContext: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let name: String
    public let tabIDs: [UUID]
    public let isCurrent: Bool

    public init(id: UUID, name: String, tabIDs: [UUID] = [], isCurrent: Bool = false) {
        self.id = id
        self.name = name
        self.tabIDs = tabIDs
        self.isCurrent = isCurrent
    }
}

public struct CommandBarContext: Hashable, Sendable {
    public var tabs: [CommandTabContext]
    public var spaces: [CommandSpaceContext]
    public var selectedTabID: UUID?
    public var selectedSpaceID: UUID?
    public var canReopenLastClosed: Bool

    public init(
        tabs: [CommandTabContext] = [],
        spaces: [CommandSpaceContext] = [],
        selectedTabID: UUID? = nil,
        selectedSpaceID: UUID? = nil,
        canReopenLastClosed: Bool = false
    ) {
        self.tabs = tabs
        self.spaces = spaces
        self.selectedTabID = selectedTabID
        self.selectedSpaceID = selectedSpaceID
        self.canReopenLastClosed = canReopenLastClosed
    }
}
