import Foundation
import RedentKit
import Testing
@testable import RedentVault

@Suite("Bookmark storage")
struct BookmarkStoreTests {
    private func makeStore() -> JSONBookmarkStore {
        let url = FileManager.default.temporaryDirectory
            .appending(path: "redent-bm-\(UUID().uuidString).json")
        return JSONBookmarkStore(fileURL: url)
    }

    private func url(_ text: String) throws -> URL { try #require(URL(string: text)) }

    @Test("A trailing slash is the same page")
    func dedupesTrailingSlash() async throws {
        let store = makeStore()
        let added = await store.merge([
            Bookmark(url: try url("https://example.com/docs")),
            Bookmark(url: try url("https://example.com/docs/"))
        ])
        #expect(added == 1)
        #expect(await store.all(in: nil).count == 1)
    }

    @Test("Merging the same set twice adds nothing the second time")
    func idempotentMerge() async throws {
        let store = makeStore()
        let set = [Bookmark(url: try url("https://a.com")), Bookmark(url: try url("https://b.com"))]
        #expect(await store.merge(set) == 2)
        #expect(await store.merge(set) == 0)
    }

    @Test("Favorites are the ones marked for the new-tab page")
    func favorites() async throws {
        let store = makeStore()
        await store.merge([
            Bookmark(url: try url("https://a.com"), isFavorite: true),
            Bookmark(url: try url("https://b.com"), isFavorite: false)
        ])
        let favorites = await store.favorites(in: nil)
        #expect(favorites.map(\.origin?.host) == ["a.com"])
    }

    @Test("Search matches title, host and folder")
    func search() async throws {
        let store = makeStore()
        await store.merge([
            Bookmark(url: try url("https://a.com"), title: "Design notes", folderPath: ["Work"]),
            Bookmark(url: try url("https://b.com"), title: "Recipes", folderPath: ["Home"])
        ])
        #expect(await store.search("design", in: nil, limit: 5).count == 1)
        #expect(await store.search("work", in: nil, limit: 5).count == 1)
        #expect(await store.search("b.com", in: nil, limit: 5).count == 1)
    }

    @Test("A missing file behaves as an empty store")
    func missingFile() async {
        #expect(await makeStore().all(in: nil).isEmpty)
    }

    @Test("Bookmarks are only visible in the Space that owns them")
    func spaceScoping() async throws {
        let store = makeStore()
        let other = UUID()
        await store.merge([
            Bookmark(url: try url("https://a.com"), spaceID: BrowserSpace.workID, isFavorite: true),
            Bookmark(url: try url("https://b.com"), spaceID: other, isFavorite: true)
        ])
        #expect(await store.all(in: BrowserSpace.workID).count == 1)
        #expect(await store.favorites(in: other).map(\.origin?.host) == ["b.com"])
        #expect(await store.all(in: nil).count == 2)
    }

    @Test("The same page saved in two Spaces is two bookmarks")
    func sameURLInTwoSpaces() async throws {
        let store = makeStore()
        let added = await store.merge([
            Bookmark(url: try url("https://example.com"), spaceID: BrowserSpace.workID),
            Bookmark(url: try url("https://example.com"), spaceID: BrowserSpace.travelID)
        ])
        #expect(added == 2)
        #expect(await store.all(in: BrowserSpace.travelID).count == 1)
    }

    @Test("Bookmarks written before Spaces were profiles join Work")
    func legacyBookmarksJoinWork() async throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appending(path: "redent-bm-legacy-\(UUID().uuidString).json")
        let legacy = """
        [{"id":"\(UUID().uuidString)","url":"https://old.example","title":"Old",
        "folderPath":[],"addedAt":0,"isFavorite":true}]
        """
        try Data(legacy.replacingOccurrences(of: "\n", with: "").utf8).write(to: fileURL)
        let store = JSONBookmarkStore(fileURL: fileURL)
        #expect(await store.all(in: BrowserSpace.workID).count == 1)
    }

    @Test("Empty folders persist with their Space")
    func emptyFoldersPersist() async {
        let store = makeStore()
        let folder = BookmarkFolder(path: ["Bookmarks Bar", "Work"], spaceID: BrowserSpace.workID)
        await store.saveFolder(folder)

        #expect(await store.folders(in: BrowserSpace.workID).map(\.label) == ["Bookmarks Bar / Work"])
        #expect(await store.folders(in: BrowserSpace.travelID).isEmpty)
    }
}
