import Foundation

/// What a namer may see of one tab: its title and site, never the page, the
/// path, or the query.
public struct TabGroupPage: Sendable, Equatable {
    public let title: String
    public let host: String

    public init(title: String, host: String) {
        self.title = title
        self.host = host
    }
}

/// Labels a cluster of tabs with a short topic. Implementations must stay on
/// the device; nil means "no better name", and the site name is shown.
public protocol TabGroupNaming: Sendable {
    func name(for pages: [TabGroupPage]) async -> String?
}
