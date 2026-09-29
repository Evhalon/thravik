import Foundation

public enum HistorySort: String, Hashable, Sendable, Codable {
    case relevance
    case recent
    case mostVisited
}

/// Search text, scope, and bounded result policy for the history browser.
public struct HistoryQuery: Hashable, Sendable, Codable {
    public var text: String
    public var scope: HistoryScope
    public var limit: Int
    public var sort: HistorySort

    public init(
        text: String = "",
        scope: HistoryScope = .all,
        limit: Int = 50,
        sort: HistorySort = .relevance
    ) {
        self.text = text
        self.scope = scope
        self.limit = max(0, limit)
        self.sort = sort
    }
}
