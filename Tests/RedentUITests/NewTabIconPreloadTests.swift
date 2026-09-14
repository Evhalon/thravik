import Foundation
import RedentKit
import Testing
@testable import RedentUI

@MainActor
@Suite("New-tab icon preloading")
struct NewTabIconPreloadTests {
    @Test("Only favorite hosts without stored icons are queued")
    func queuesHostsMissingStoredIcons() async throws {
        let spaceID = UUID()
        let missing = Bookmark(url: try url("https://github.com"), spaceID: spaceID, isFavorite: true)
        let stored = Bookmark(
            url: try url("https://swift.org"), spaceID: spaceID, isFavorite: true, faviconData: Data([1])
        )
        let duplicate = Bookmark(url: try url("https://www.github.com"), spaceID: spaceID, isFavorite: true)
        let model = NewTabModel(history: EmptyHistoryStore(), bookmarks: IconBookmarkStore([missing, stored, duplicate]))

        await model.load(in: spaceID)

        #expect(model.favoriteHostsMissingIcons == ["github.com"])
    }

    private func url(_ value: String) throws -> URL {
        try #require(URL(string: value))
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

private struct IconBookmarkStore: BookmarkStoring {
    let bookmarks: [Bookmark]

    init(_ bookmarks: [Bookmark]) { self.bookmarks = bookmarks }

    func all(in _: UUID?) async -> [Bookmark] { bookmarks }
    func favorites(in _: UUID?) async -> [Bookmark] { bookmarks }
    func search(_: String, in _: UUID?, limit _: Int) async -> [Bookmark] { [] }
    func bookmark(for url: URL, in _: UUID?) async -> Bookmark? { bookmarks.first { $0.url == url } }
    func save(_: Bookmark) async {}
    func merge(_: [Bookmark]) async -> Int { 0 }
    func delete(_: UUID) async {}
}
