import Foundation
import RedentKit
import Testing
@testable import RedentUI

@MainActor
@Suite("New-tab favorite names")
struct NewTabFavoriteNamingTests {
    @Test("Renaming a favorite updates its home-page label")
    func renamesFavorite() async throws {
        let bookmark = Bookmark(
            url: try #require(URL(string: "https://docs.example.com")),
            title: "Documentation",
            spaceID: BrowserSpace.workID,
            isFavorite: true
        )
        let store = FavoriteNameStore(bookmark)
        let model = NewTabModel(history: EmptyHistoryStore(), bookmarks: store)

        await model.load(in: BrowserSpace.workID)
        let tile = try #require(model.rootFavoriteTiles.first)
        #expect(tile.title == "Documentation")
        #expect(await model.renameFavorite(tile, to: "Project docs"))
        #expect(model.rootFavoriteTiles.first?.title == "Project docs")
        #expect(await store.favorite()?.title == "Project docs")
    }

    @Test("A blank favorite name is rejected")
    func rejectsBlankName() async throws {
        let bookmark = Bookmark(
            url: try #require(URL(string: "https://docs.example.com")),
            spaceID: BrowserSpace.workID,
            isFavorite: true
        )
        let model = NewTabModel(history: EmptyHistoryStore(), bookmarks: FavoriteNameStore(bookmark))
        await model.load(in: BrowserSpace.workID)

        #expect(await model.renameFavorite(try #require(model.rootFavoriteTiles.first), to: "  ") == false)
    }
}

private struct EmptyHistoryStore: HistoryStoring {
    func query(_: HistoryQuery) async -> [HistoryEntry] { [] }
    func mostVisited(limit _: Int) async -> [HistoryEntry] { [] }
    func record(url _: URL, title _: String, at _: Date) async {}
    func search(_: String, limit _: Int) async -> [HistoryEntry] { [] }
    func recent(limit _: Int) async -> [HistoryEntry] { [] }
    func merge(_: [HistoryEntry]) async {}
    func delete(_: UUID) async {}
    func clearAll() async {}
}

private actor FavoriteNameStore: BookmarkStoring {
    private var bookmark: Bookmark

    init(_ bookmark: Bookmark) { self.bookmark = bookmark }

    func all(in _: UUID?) async -> [Bookmark] { [bookmark] }
    func favorites(in _: UUID?) async -> [Bookmark] { [bookmark] }
    func search(_: String, in _: UUID?, limit _: Int) async -> [Bookmark] { [] }
    func bookmark(for url: URL, in _: UUID?) async -> Bookmark? { bookmark.url == url ? bookmark : nil }
    func save(_ bookmark: Bookmark) async { self.bookmark = bookmark }
    func merge(_: [Bookmark]) async -> Int { 0 }
    func delete(_: UUID) async {}
    func favorite() -> Bookmark? { bookmark }
}
