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
    /// False when no name can come — the model is missing or switched off —
    /// so the site name is shown straight away instead of waiting for one.
    var isAvailable: Bool { get }
    func name(for pages: [TabGroupPage]) async -> String?
}

extension TabGroupNaming {
    public var isAvailable: Bool { true }
}
