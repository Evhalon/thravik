import Foundation
import RedentKit
import Testing
@testable import RedentUI

@MainActor @Suite("New-tab favorite folders")
struct FavoriteFoldersModelTests {
    @Test("A new folder is saved in the active Space")
    func createsFolderInCurrentSpace() async {
        let store = FavoriteFolderStore()
        let model = NewTabModel(history: EmptyHistoryStore(), bookmarks: store)
        await model.load(in: BrowserSpace.personalID)
        #expect(model.isBare)
        #expect(await model.createFavoriteFolder(named: "Reading"))
        #expect(model.favoriteFolders.map(\.name) == ["Reading"])
        #expect(!model.isBare)
        #expect(await store.folders(in: BrowserSpace.personalID).count == 1)
        #expect(await store.folders(in: BrowserSpace.workID).isEmpty)
    }

    @Test("Dropping a favorite into a folder preserves its favorite state")
    func movesFavoriteIntoFolder() async throws {
        let bookmark = Bookmark(
            url: try #require(URL(string: "https://redent.app")),
            title: "Redent",
            spaceID: BrowserSpace.workID,
            isFavorite: true
        )
        let store = FavoriteFolderStore(bookmarks: [bookmark])
        let model = NewTabModel(history: EmptyHistoryStore(), bookmarks: store)
        await model.load(in: BrowserSpace.workID)
        #expect(await model.createFavoriteFolder(named: "Browser"))
        let folder = try #require(model.favoriteFolders.first)
        await model.moveFavorite(bookmark.id, into: folder)
        let saved = try #require(await store.bookmark(id: bookmark.id))
        #expect(saved.folderPath == ["Browser"])
        #expect(saved.isFavorite)
        #expect(model.rootFavoriteTiles.isEmpty)
        #expect(model.favoriteFolders.first?.favoriteCount == 1)
        await model.removeFavoriteFromFolder(bookmark.id)
        #expect((await store.bookmark(id: bookmark.id))?.folderPath.isEmpty == true)
        #expect(model.rootFavoriteTiles.map(\.bookmarkID) == [bookmark.id])
    }

    @Test("A folder keeps separate favorites from the same host")
    func folderDoesNotCollapseSameHostFavorites() async throws {
        let first = Bookmark(
            url: try #require(URL(string: "https://redent.app/docs")),
            spaceID: BrowserSpace.workID,
            isFavorite: true
        )
        let second = Bookmark(
            url: try #require(URL(string: "https://redent.app/blog")),
            spaceID: BrowserSpace.workID,
            isFavorite: true
        )
        let store = FavoriteFolderStore(bookmarks: [first, second])
        let model = NewTabModel(history: EmptyHistoryStore(), bookmarks: store)

        await model.load(in: BrowserSpace.workID)
        #expect(await model.createFavoriteFolder(named: "Redent"))
        let folder = try #require(model.favoriteFolders.first)
        await model.moveFavorite(first.id, into: folder)
        await model.moveFavorite(second.id, into: folder)

        #expect(model.favoriteFolders.first?.favoriteCount == 2)
        #expect(model.favoriteTiles(in: folder).map(\.bookmarkID) == [second.id, first.id])
    }

    @Test("Deleting a folder returns its favorites to the root")
    func deletesFolderWithoutDeletingFavorites() async throws {
        let bookmark = Bookmark(
            url: try #require(URL(string: "https://redent.app")),
            folderPath: ["Reading"], spaceID: BrowserSpace.workID, isFavorite: true
        )
        let folder = BookmarkFolder(path: ["Reading"], spaceID: BrowserSpace.workID)
        let store = FavoriteFolderStore(bookmarks: [bookmark], folders: [folder])
        let model = NewTabModel(history: EmptyHistoryStore(), bookmarks: store)

        await model.load(in: BrowserSpace.workID)
        await model.deleteFavoriteFolder(try #require(model.favoriteFolders.first))

        #expect(model.favoriteFolders.isEmpty)
        #expect(model.rootFavoriteTiles.map(\.bookmarkID) == [bookmark.id])
        #expect(await store.folders(in: BrowserSpace.workID).isEmpty)
    }
}

private struct EmptyHistoryStore: HistoryStoring {
    func query(_ request: HistoryQuery) async -> [HistoryEntry] { [] }
    func mostVisited(limit: Int) async -> [HistoryEntry] { [] }
    func record(url: URL, title: String, at date: Date) async {}
    func search(_ query: String, limit: Int) async -> [HistoryEntry] { [] }
    func recent(limit: Int) async -> [HistoryEntry] { [] }
    func merge(_ entries: [HistoryEntry]) async {}
    func delete(_ id: UUID) async {}
    func clearAll() async {}
}

private actor FavoriteFolderStore: BookmarkStoring {
    private var bookmarks: [Bookmark]
    private var savedFolders: [BookmarkFolder]

    init(bookmarks: [Bookmark] = [], folders: [BookmarkFolder] = []) {
        self.bookmarks = bookmarks
        savedFolders = folders
    }

    func all(in spaceID: UUID?) async -> [Bookmark] { scoped(bookmarks, to: spaceID) }

    func favorites(in spaceID: UUID?) async -> [Bookmark] {
        scoped(bookmarks, to: spaceID).filter(\.isFavorite)
    }

    func search(_ query: String, in spaceID: UUID?, limit: Int) async -> [Bookmark] { [] }

    func bookmark(for url: URL, in spaceID: UUID?) async -> Bookmark? { nil }

    func bookmark(id: UUID) -> Bookmark? { bookmarks.first { $0.id == id } }

    func save(_ bookmark: Bookmark) async {
        guard let index = bookmarks.firstIndex(where: { $0.id == bookmark.id }) else {
            bookmarks.append(bookmark)
            return
        }
        bookmarks[index] = bookmark
    }

    func merge(_ bookmarks: [Bookmark]) async -> Int { 0 }

    func delete(_ id: UUID) async {}

    func folders(in spaceID: UUID?) async -> [BookmarkFolder] {
        guard let spaceID else { return savedFolders }
        return savedFolders.filter { $0.spaceID == spaceID }
    }

    func saveFolder(_ folder: BookmarkFolder) async {
        savedFolders.append(folder)
    }

    func deleteFolder(_ folder: BookmarkFolder) async {
        savedFolders.removeAll { $0.spaceID == folder.spaceID && $0.path == folder.path }
    }

    private func scoped(_ values: [Bookmark], to spaceID: UUID?) -> [Bookmark] {
        guard let spaceID else { return values }
        return values.filter { $0.spaceID == spaceID }
    }
}
