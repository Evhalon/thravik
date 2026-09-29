import Foundation

/// A browser window as the Command Bar lists it.
public struct CommandWindowContext: Identifiable, Hashable, Sendable {
    public let id: UUID
    /// What the window is showing: its selected tab's title.
    public let title: String
    public let tabCount: Int
    public let isPrivate: Bool
    public let isCurrent: Bool
    /// The web app this window was opened for, if any.
    public let webAppID: UUID?

    public init(id: UUID, title: String, tabCount: Int, flags: Flags = .init()) {
        self.id = id
        self.title = title
        self.tabCount = tabCount
        self.isPrivate = flags.isPrivate
        self.isCurrent = flags.isCurrent
        self.webAppID = flags.webAppID
    }

    public struct Flags: Hashable, Sendable {
        public var isPrivate: Bool
        public var isCurrent: Bool
        public var webAppID: UUID?

        public init(isPrivate: Bool = false, isCurrent: Bool = false, webAppID: UUID? = nil) {
            self.isPrivate = isPrivate
            self.isCurrent = isCurrent
            self.webAppID = webAppID
        }
    }
}
