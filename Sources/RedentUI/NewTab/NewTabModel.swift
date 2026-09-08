import Foundation
import Observation
import RedentKit

/// Everything the new-tab page shows, loaded once when it appears.
@MainActor @Observable
public final class NewTabModel {
    public private(set) var favorites: [Bookmark] = []
    public private(set) var frequent: [HistoryEntry] = []
    public private(set) var hasLoaded = false

    private let history: any HistoryStoring
    private let bookmarks: any BookmarkStoring

    public init(history: any HistoryStoring, bookmarks: any BookmarkStoring) {
        self.history = history
        self.bookmarks = bookmarks
    }

    /// True before anything has ever been visited or imported — the page shows
    /// an invitation to import instead of an empty grid.
    public var isBare: Bool { hasLoaded && favorites.isEmpty && frequent.isEmpty }

    public func load(in spaceID: UUID?) async {
        async let saved = bookmarks.favorites(in: spaceID)
        async let visited = history.mostVisited(limit: 12)
        favorites = Array(await saved.prefix(12))
        frequent = await visited
        hasLoaded = true
    }

    /// The tiles actually rendered: favorites first, topped up with
    /// most-visited sites so a fresh profile still has something useful.
    public var tiles: [NewTabTile] {
        var seen = Set<String>()
        var result: [NewTabTile] = []
        for bookmark in favorites {
            guard let host = bookmark.origin?.displayHost, seen.insert(host).inserted else { continue }
            result.append(NewTabTile(
                url: bookmark.url,
                title: bookmark.displayTitle,
                host: host,
                faviconData: bookmark.faviconData,
                isFavorite: true
            ))
        }
        for entry in frequent {
            guard result.count < 12,
                  let host = entry.origin?.displayHost,
                  seen.insert(host).inserted
            else { continue }
            result.append(NewTabTile(
                url: entry.url,
                title: entry.displayTitle,
                host: host,
                faviconData: nil,
                isFavorite: false
            ))
        }
        return result
    }
}

public struct NewTabTile: Identifiable, Hashable, Sendable {
    public let url: URL
    public let title: String
    public let host: String
    public let faviconData: Data?
    public let isFavorite: Bool

    public var id: String { url.absoluteString }
}
