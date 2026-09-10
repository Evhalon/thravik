import Foundation
import Observation
import RedentKit

/// Everything the new-tab page shows, loaded once when it appears.
@MainActor @Observable
public final class NewTabModel {
    public private(set) var favorites: [Bookmark] = []
    public private(set) var savedFolders: [BookmarkFolder] = []
    public private(set) var frequent: [HistoryEntry] = []
    public private(set) var hasLoaded = false

    private let history: any HistoryStoring
    let bookmarks: any BookmarkStoring
    var spaceID: UUID?

    public init(history: any HistoryStoring, bookmarks: any BookmarkStoring) {
        self.history = history
        self.bookmarks = bookmarks
    }

    /// True before anything has ever been visited or imported — the page shows
    /// an invitation to import instead of an empty grid.
    public var isBare: Bool {
        hasLoaded && favorites.isEmpty && frequent.isEmpty && savedFolders.isEmpty
    }

    public func load(in spaceID: UUID?) async {
        async let saved = bookmarks.favorites(in: spaceID)
        async let folders = bookmarks.folders(in: spaceID)
        async let visited = frequentSites(in: spaceID)
        self.spaceID = spaceID
        favorites = await saved
        savedFolders = await folders
        frequent = await visited
        hasLoaded = true
    }

    public var favoriteFolders: [FavoriteFolder] {
        let paths = Set(savedFolders.map(\.path)).union(
            favorites.filter { !$0.folderPath.isEmpty }.map(\.folderPath)
        )
        return paths.sorted { $0.joined(separator: "/") < $1.joined(separator: "/") }
            .map { path in
                FavoriteFolder(path: path, favoriteCount: favorites.count { $0.folderPath == path })
            }
    }

    public var rootFavoriteTiles: [NewTabTile] {
        favoriteTiles(from: favorites.filter(\.folderPath.isEmpty), limit: Self.tileLimit, uniquingHosts: true)
    }

    public var frequentTiles: [NewTabTile] {
        let savedHosts = Set(favorites.compactMap { $0.origin?.displayHost })
        return frequentTiles(excluding: savedHosts, limit: Self.tileLimit)
    }

    public func favoriteTiles(in folder: FavoriteFolder) -> [NewTabTile] {
        favoriteTiles(from: favorites.filter { $0.folderPath == folder.path }, limit: nil, uniquingHosts: false)
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
        let favorites = rootFavoriteTiles
        let hosts = Set(favorites.map(\.host))
        return favorites + frequentTiles(excluding: hosts, limit: Self.tileLimit - favorites.count)
    }

    private func favoriteTiles(
        from bookmarks: [Bookmark], limit: Int?, uniquingHosts: Bool
    ) -> [NewTabTile] {
        var seen = Set<String>()
        var tiles: [NewTabTile] = []
        for bookmark in bookmarks.sorted(by: { $0.addedAt > $1.addedAt }) {
            guard let host = bookmark.origin?.displayHost else { continue }
            if uniquingHosts && !seen.insert(host).inserted { continue }
            tiles.append(NewTabTile(
                url: bookmark.url,
                title: bookmark.displayTitle,
                host: host,
                faviconData: bookmark.faviconData,
                isFavorite: true,
                bookmarkID: bookmark.id
            ))
            if let limit, tiles.count == limit { break }
        }
        return tiles
    }

    private func frequentTiles(excluding hosts: Set<String>, limit: Int) -> [NewTabTile] {
        guard limit > 0 else { return [] }
        var seen = hosts
        var tiles: [NewTabTile] = []
        for entry in frequent {
            guard let host = entry.origin?.displayHost, seen.insert(host).inserted else { continue }
            tiles.append(NewTabTile(url: entry.url, title: entry.displayTitle, host: host, faviconData: nil))
            if tiles.count == limit { break }
        }
        return tiles
    }

}
