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
    private var spaceID: UUID?

    public init(history: any HistoryStoring, bookmarks: any BookmarkStoring) {
        self.history = history
        self.bookmarks = bookmarks
    }

    /// True before anything has ever been visited or imported — the page shows
    /// an invitation to import instead of an empty grid.
    public var isBare: Bool { hasLoaded && favorites.isEmpty && frequent.isEmpty }

    public func load(in spaceID: UUID?) async {
        self.spaceID = spaceID
        async let saved = bookmarks.favorites(in: spaceID)
        async let visited = frequentSites(in: spaceID)
        favorites = Array(await saved.prefix(Self.tileLimit))
        frequent = await visited
        hasLoaded = true
    }

    /// Unstar a home tile. The bookmark stays in the manager; it just leaves
    /// the grid.
    public func removeFavorite(_ tile: NewTabTile) async {
        guard let id = tile.bookmarkID,
              var bookmark = favorites.first(where: { $0.id == id }),
              bookmark.isFavorite
        else { return }
        bookmark.isFavorite = false
        await bookmarks.save(bookmark)
        await load(in: spaceID)
    }

    /// Most-visited sites counted within the Space being viewed, so a work
    /// Space never suggests what was browsed in a personal one.
    private func frequentSites(in spaceID: UUID?) async -> [HistoryEntry] {
        guard let spaceID else { return await history.mostVisited(limit: Self.tileLimit) }
        return await history.query(HistoryQuery(
            scope: HistoryScope(spaceID: spaceID), limit: Self.tileLimit, sort: .mostVisited
        ))
    }

    private static let tileLimit = 12

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
                isFavorite: true,
                bookmarkID: bookmark.id
            ))
        }
        for entry in frequent {
            guard result.count < Self.tileLimit,
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
