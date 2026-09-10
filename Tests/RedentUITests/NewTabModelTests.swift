import Foundation
import RedentKit
import Testing
@testable import RedentUI

/// The new-tab grid belongs to the Space it is opened in.
@MainActor
@Suite("Frequently visited is per Space")
struct NewTabModelTests {
    private func page(_ value: String) throws -> URL { try #require(URL(string: value)) }

    @Test("Only the sites visited in this Space are suggested")
    func frequentIsScopedToSpace() async throws {
        let history = SpacedHistoryStore(bySpace: [
            BrowserSpace.workID: [HistoryEntry(url: try page("https://tracker.work/"))],
            BrowserSpace.personalID: [HistoryEntry(url: try page("https://forum.home/"))]
        ])
        let model = NewTabModel(history: history, bookmarks: EmptyBookmarkStore())

        await model.load(in: BrowserSpace.workID)
        #expect(model.tiles.map(\.host) == ["tracker.work"])

        await model.load(in: BrowserSpace.personalID)
        #expect(model.tiles.map(\.host) == ["forum.home"])
    }

    @Test("A new Space does not inherit another Space's frequent sites")
    func emptySpaceStaysEmpty() async throws {
        let history = SpacedHistoryStore(
            bySpace: [BrowserSpace.workID: [HistoryEntry(url: try page("https://tracker.work/"))]]
        )
        let model = NewTabModel(history: history, bookmarks: EmptyBookmarkStore())

        await model.load(in: BrowserSpace.travelID)
        #expect(model.tiles.isEmpty)
        #expect(model.isBare)
    }

    @Test("Favorite tiles keep the bookmark's own favicon")
    func favoriteKeepsFavicon() async throws {
        let icon = Data([0x00, 0x00, 0x01, 0x00])
        let bookmark = Bookmark(url: try page("https://www.github.com"), isFavorite: true, faviconData: icon)
        let store = ListedBookmarkStore(bookmarks: [bookmark])
        let model = NewTabModel(
            history: SpacedHistoryStore(bySpace: [:]),
            bookmarks: store
        )
        await model.load(in: nil)
        #expect(model.tiles.map(\.host) == ["github.com"])
        #expect(model.tiles.first?.faviconData == icon)
        #expect(model.tiles.first?.isFavorite == true)
        #expect(model.tiles.first?.bookmarkID == bookmark.id)
    }

    @Test("Unstarring a home tile keeps the bookmark but leaves the grid")
    func removeFavoriteUnstars() async throws {
        let bookmark = Bookmark(
            url: try page("https://ordigo.app"),
            title: "OrdiGO",
            isFavorite: true
        )
        let store = ListedBookmarkStore(bookmarks: [bookmark])
        let model = NewTabModel(
            history: SpacedHistoryStore(bySpace: [:]),
            bookmarks: store
        )
        await model.load(in: nil)
        let tile = try #require(model.tiles.first)
        await model.removeFavorite(tile)
        #expect(model.tiles.filter(\.isFavorite).isEmpty)
        #expect(await store.bookmarks.first?.isFavorite == false)
        #expect(await store.bookmarks.first?.url == bookmark.url)
    }
}

/// History that answers scoped queries the way the SQLite store does.
private struct SpacedHistoryStore: HistoryStoring {
    let bySpace: [UUID: [HistoryEntry]]

    func query(_ request: HistoryQuery) async -> [HistoryEntry] {
        guard let spaceID = request.scope.spaceID else { return await mostVisited(limit: request.limit) }
        return Array((bySpace[spaceID] ?? []).prefix(request.limit))
    }

    func mostVisited(limit: Int) async -> [HistoryEntry] {
        Array(bySpace.values.flatMap { $0 }.prefix(limit))
    }

    func record(url: URL, title: String, at date: Date) async {}
    func search(_ query: String, limit: Int) async -> [HistoryEntry] { [] }
    func recent(limit: Int) async -> [HistoryEntry] { [] }
    func merge(_ entries: [HistoryEntry]) async {}
    func delete(_ id: UUID) async {}
    func clearAll() async {}
}

private struct EmptyBookmarkStore: BookmarkStoring {
    func all(in spaceID: UUID?) async -> [Bookmark] { [] }
    func favorites(in spaceID: UUID?) async -> [Bookmark] { [] }
    func search(_ query: String, in spaceID: UUID?, limit: Int) async -> [Bookmark] { [] }
    func bookmark(for url: URL, in spaceID: UUID?) async -> Bookmark? { nil }
    func save(_ bookmark: Bookmark) async {}
    func merge(_ bookmarks: [Bookmark]) async -> Int { 0 }
    func delete(_ id: UUID) async {}
}

private actor ListedBookmarkStore: BookmarkStoring {
    var bookmarks: [Bookmark]

    init(bookmarks: [Bookmark]) { self.bookmarks = bookmarks }

    func all(in spaceID: UUID?) async -> [Bookmark] { bookmarks }
    func favorites(in spaceID: UUID?) async -> [Bookmark] { bookmarks.filter(\.isFavorite) }
    func search(_ query: String, in spaceID: UUID?, limit: Int) async -> [Bookmark] { [] }
    func bookmark(for url: URL, in spaceID: UUID?) async -> Bookmark? {
        bookmarks.first { $0.url == url }
    }
    func merge(_ bookmarks: [Bookmark]) async -> Int { 0 }
    func delete(_ id: UUID) async {}

    func save(_ bookmark: Bookmark) async {
        if let index = bookmarks.firstIndex(where: { $0.id == bookmark.id }) {
            bookmarks[index] = bookmark
        } else {
            bookmarks.append(bookmark)
        }
    }
}
