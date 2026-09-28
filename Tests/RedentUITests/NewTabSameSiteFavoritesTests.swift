import Foundation
import RedentKit
import Testing
@testable import RedentUI

@MainActor
@Suite("Favorites on the same site")
struct NewTabSameSiteFavoritesTests {
    @Test("Two favorites on one site each keep their own tile")
    func sameHostFavorites() async throws {
        let older = Bookmark(
            url: try #require(URL(string: "https://docs.example/a")), title: "A",
            spaceID: BrowserSpace.workID, addedAt: .distantPast, isFavorite: true
        )
        let newer = Bookmark(
            url: try #require(URL(string: "https://docs.example/b")), title: "B",
            spaceID: BrowserSpace.workID, isFavorite: true
        )
        let model = NewTabModel(history: NoHistory(), bookmarks: TwoFavorites(bookmarks: [older, newer]))

        await model.load(in: BrowserSpace.workID)
        #expect(model.tiles.map(\.bookmarkID) == [newer.id, older.id])
        #expect(model.tiles.map(\.url) == [newer.url, older.url])
        #expect(model.tiles.map(\.title) == ["B", "A"])
    }
}

private struct NoHistory: HistoryStoring {
    func query(_: HistoryQuery) async -> [HistoryEntry] { [] }
    func mostVisited(limit _: Int) async -> [HistoryEntry] { [] }
    func record(url _: URL, title _: String, at _: Date) async {}
    func search(_: String, limit _: Int) async -> [HistoryEntry] { [] }
    func recent(limit _: Int) async -> [HistoryEntry] { [] }
    func merge(_: [HistoryEntry]) async {}
    func delete(_: UUID) async {}
    func clearAll() async {}
}

private struct TwoFavorites: BookmarkStoring {
    let bookmarks: [Bookmark]

    func all(in _: UUID?) async -> [Bookmark] { bookmarks }
    func favorites(in _: UUID?) async -> [Bookmark] { bookmarks }
    func search(_: String, in _: UUID?, limit _: Int) async -> [Bookmark] { [] }
    func bookmark(for url: URL, in _: UUID?) async -> Bookmark? { bookmarks.first { $0.url == url } }
    func save(_: Bookmark) async {}
    func merge(_: [Bookmark]) async -> Int { 0 }
    func delete(_: UUID) async {}
}
