import Foundation

/// A destination shown on the new-tab surface.
public struct NewTabTile: Identifiable, Hashable, Sendable {
    public let url: URL
    public let title: String
    public let host: String
    public let faviconData: Data?
    public let isFavorite: Bool
    public let bookmarkID: UUID?

    public init(
        url: URL,
        title: String,
        host: String,
        faviconData: Data?,
        isFavorite: Bool = false,
        bookmarkID: UUID? = nil
    ) {
        self.url = url
        self.title = title
        self.host = host
        self.faviconData = faviconData
        self.isFavorite = isFavorite
        self.bookmarkID = bookmarkID
    }

    public var id: String { bookmarkID?.uuidString ?? url.absoluteString }
}
