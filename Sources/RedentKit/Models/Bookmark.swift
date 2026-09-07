import Foundation

/// A saved page. Folders are a path rather than a tree: the tree only ever
/// gets flattened for display, and a path makes import and search trivial.
public struct Bookmark: Identifiable, Hashable, Sendable, Codable {
    public let id: UUID
    public var url: URL
    public var title: String
    /// `["Bookmarks Bar", "Work"]`. Empty means top level.
    public var folderPath: [String]
    public var addedAt: Date
    /// Bookmarks the user pinned to the new-tab grid.
    public var isFavorite: Bool
    public var faviconData: Data?

    public init(
        id: UUID = UUID(),
        url: URL,
        title: String = "",
        folderPath: [String] = [],
        addedAt: Date = .now,
        isFavorite: Bool = false,
        faviconData: Data? = nil
    ) {
        self.id = id
        self.url = url
        self.title = title
        self.folderPath = folderPath
        self.addedAt = addedAt
        self.isFavorite = isFavorite
        self.faviconData = faviconData
    }

    public var origin: Origin? { Origin(url: url) }

    public var displayTitle: String {
        title.isEmpty ? (origin?.displayHost ?? url.absoluteString) : title
    }

    public var folderLabel: String {
        folderPath.isEmpty ? "All Bookmarks" : folderPath.joined(separator: " / ")
    }
}
