import Foundation
import RedentKit
import Testing
@testable import RedentUI

@Suite("Bookmarks manager")
struct BookmarksModelTests {
    @Test("Adding a bookmark saves it as a new-tab favorite") @MainActor
    func create() async throws {
        let store = BookmarkStoreFake(bookmarks: [])
        let model = BookmarksModel(store: store, spaces: [], spaceID: BrowserSpace.workID)

        #expect(await model.create(title: "Redent", address: "https://redent.app"))
        let saved = try #require(await store.bookmarks.first)
        #expect(saved.title == "Redent")
        #expect(saved.isFavorite)
        #expect(saved.spaceID == BrowserSpace.workID)
    }

    @Test("Renaming keeps the address and persists the new title") @MainActor
    func rename() async throws {
        let bookmark = Bookmark(url: try #require(URL(string: "https://redent.app")), title: "Old")
        let store = BookmarkStoreFake(bookmarks: [bookmark])
        let model = BookmarksModel(store: store, spaces: [], spaceID: nil)

        #expect(await model.rename(bookmark, to: "New"))
        let saved = try #require(await store.bookmarks.first)
        #expect(saved.title == "New")
        #expect(saved.url == bookmark.url)
    }

    @Test("Changing the address only accepts web URLs") @MainActor
    func changeAddress() async throws {
        let bookmark = Bookmark(url: try #require(URL(string: "https://old.example")))
        let store = BookmarkStoreFake(bookmarks: [bookmark])
        let model = BookmarksModel(store: store, spaces: [], spaceID: nil)

        #expect(!(await model.changeAddress(bookmark, to: "not a URL")))
        #expect(await model.changeAddress(bookmark, to: "https://new.example/path"))
        let saved = try #require(await store.bookmarks.first)
        #expect(saved.url.absoluteString == "https://new.example/path")
    }
}

private actor BookmarkStoreFake: BookmarkStoring {
    var bookmarks: [Bookmark]

    init(bookmarks: [Bookmark]) { self.bookmarks = bookmarks }

    func all(in spaceID: UUID?) async -> [Bookmark] { bookmarks }
    func favorites(in spaceID: UUID?) async -> [Bookmark] { [] }
    func search(_ query: String, in spaceID: UUID?, limit: Int) async -> [Bookmark] { [] }
    func bookmark(for url: URL, in spaceID: UUID?) async -> Bookmark? { nil }
    func merge(_ bookmarks: [Bookmark]) async -> Int { 0 }
    func delete(_ id: UUID) async {}

    func save(_ bookmark: Bookmark) async {
        guard let index = bookmarks.firstIndex(where: { $0.id == bookmark.id }) else {
            bookmarks.append(bookmark)
            return
        }
        bookmarks[index] = bookmark
    }
}
