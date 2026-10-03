import Foundation

/// A closed tab or tab group the UI may list without WebKit or engine types.
public struct RecentlyClosedEntry: Identifiable, Sendable, Hashable {
    public let id: UUID
    public let title: String
    public let host: String?
    public let faviconData: Data?
    public let closedAt: Date
    public let kind: RecentlyClosedKind

    public init(
        id: UUID,
        title: String,
        host: String?,
        faviconData: Data?,
        closedAt: Date,
        kind: RecentlyClosedKind
    ) {
        self.id = id
        self.title = title
        self.host = host
        self.faviconData = faviconData
        self.closedAt = closedAt
        self.kind = kind
    }
}
