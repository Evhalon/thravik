import Foundation
import RedentKit
import Testing
@testable import RedentUI

@Suite("Bookmarks bar model")
struct BookmarksBarModelTests {
    @Test("Load keeps the current Space's top-level chips")
    @MainActor
    func loadsTopLevelForSpace() async throws {
        let work = Bookmark(
            url: try url("https://work.example"), title: "Work", spaceID: BrowserSpace.workID
        )
        let nested = Bookmark(
            url: try url("https://nested.example"), title: "Nested",
            folderPath: ["Reading"], spaceID: BrowserSpace.workID
        )
        let other = Bookmark(
            url: try url("https://personal.example"), title: "Personal",
            spaceID: BrowserSpace.personalID
        )
        let store = BarStoreFake(bookmarks: [work, nested, other])
        let model = BookmarksBarModel(store: store)

        await model.load(in: BrowserSpace.workID)

        #expect(model.items.map(\.title) == ["Work", "Reading"])
        guard case .folder(_, let pages) = model.items.last else {
            Issue.record("expected Reading folder")
            return
        }
        #expect(pages.map(\.title) == ["Nested"])
    }

    @Test("Edit writes the new title and address, then reloads")
    @MainActor
    func updatesBookmark() async throws {
        let bookmark = Bookmark(
            url: try url("https://old.example"), title: "Old", spaceID: BrowserSpace.workID
        )
        let store = BarStoreFake(bookmarks: [bookmark])
        let model = BookmarksBarModel(store: store)
        await model.load(in: BrowserSpace.workID)

        #expect(await model.update(bookmark, title: "New", address: "https://new.example/path"))
        let saved = try #require(await store.bookmarks.first)
        #expect(saved.title == "New")
        #expect(saved.url.absoluteString == "https://new.example/path")
        #expect(model.items.map(\.title) == ["New"])
    }

    @Test("Focus mode hides the bar while the setting stays on")
    @MainActor
    func hidesInFocusMode() {
        let model = makeTestBrowserModel()
        model.settings.showsBookmarksBar = true
        #expect(model.showsBookmarksBar)
        model.toggleFocusMode()
        #expect(!model.showsBookmarksBar)
        #expect(model.settings.showsBookmarksBar)
    }

    @Test("Delete removes the page from the bar")
    @MainActor
    func deletesBookmark() async throws {
        let bookmark = Bookmark(
            url: try url("https://gone.example"), title: "Gone", spaceID: BrowserSpace.workID
        )
        let store = BarStoreFake(bookmarks: [bookmark])
        let model = BookmarksBarModel(store: store)
        await model.load(in: BrowserSpace.workID)
        await model.delete(bookmark)
        #expect(model.items.isEmpty)
        #expect(await store.bookmarks.isEmpty)
    }

    @Test("Toggle ignores a Space with no bar items", arguments: [false, true])
    @MainActor
    func ignoresEmptySpace(initiallyShown: Bool) async throws {
        let elsewhere = Bookmark(
            url: try url("https://personal.example"), title: "Personal",
            spaceID: BrowserSpace.personalID
        )
        let model = makeTestBrowserModel(bookmarks: BarStoreFake(bookmarks: [elsewhere]))
        model.settings.showsBookmarksBar = initiallyShown
        await model.toggleBookmarksBar()
        #expect(model.settings.showsBookmarksBar == initiallyShown)
    }

    @Test("Toggle shows and hides a populated Space")
    @MainActor
    func togglesPopulatedSpace() async throws {
        let page = Bookmark(url: try url("https://work.example"), title: "Work", spaceID: BrowserSpace.workID)
        let model = makeTestBrowserModel(bookmarks: BarStoreFake(bookmarks: [page]))
        model.settings.showsBookmarksBar = false
        await model.toggleBookmarksBar()
        #expect(model.showsBookmarksBar)
        await model.toggleBookmarksBar()
        #expect(!model.showsBookmarksBar)
    }

    private func url(_ text: String) throws -> URL { try #require(URL(string: text)) }
}

actor BarStoreFake: BookmarkStoring {
    var bookmarks: [Bookmark]
    var savedFolders: [BookmarkFolder]

    init(bookmarks: [Bookmark], folders: [BookmarkFolder] = []) {
        self.bookmarks = bookmarks
        savedFolders = folders
    }

    func all(in spaceID: UUID?) async -> [Bookmark] {
        guard let spaceID else { return bookmarks }
        return bookmarks.filter { $0.spaceID == spaceID }
    }

    func favorites(in spaceID: UUID?) async -> [Bookmark] { [] }
    func search(_ query: String, in spaceID: UUID?, limit: Int) async -> [Bookmark] { [] }
    func bookmark(for url: URL, in spaceID: UUID?) async -> Bookmark? { nil }
    func merge(_ bookmarks: [Bookmark]) async -> Int { 0 }

    func delete(_ id: UUID) async {
        bookmarks.removeAll { $0.id == id }
    }

    func save(_ bookmark: Bookmark) async {
        guard let index = bookmarks.firstIndex(where: { $0.id == bookmark.id }) else {
            bookmarks.append(bookmark)
            return
        }
        bookmarks[index] = bookmark
    }

    func folders(in spaceID: UUID?) async -> [BookmarkFolder] {
        guard let spaceID else { return savedFolders }
        return savedFolders.filter { $0.spaceID == spaceID }
    }

    func saveFolder(_ folder: BookmarkFolder) async { savedFolders.append(folder) }
    func deleteFolder(_ folder: BookmarkFolder) async {
        savedFolders.removeAll { $0.id == folder.id }
    }
}
