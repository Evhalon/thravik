import Foundation

/// One cell on the new-tab grid: a favorite, or a most-visited stand-in.
public struct NewTabTile: Identifiable, Hashable, Sendable {
    public let url: URL
    public let title: String
    public let host: String
    public let faviconData: Data?
    public let isFavorite: Bool
    public let bookmarkID: UUID?

    public var id: String { url.absoluteString }

    public init(
        url: URL,
        title: String,
        host: String,
        faviconData: Data?,
        isFavorite: Bool,
        bookmarkID: UUID? = nil
    ) {
        self.url = url
        self.title = title
        self.host = host
        self.faviconData = faviconData
        self.isFavorite = isFavorite
        self.bookmarkID = bookmarkID
    }
}
