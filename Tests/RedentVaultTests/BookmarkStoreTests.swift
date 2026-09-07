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
        #expect(await store.all().count == 1)
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
        let favorites = await store.favorites()
        #expect(favorites.map(\.origin?.host) == ["a.com"])
    }

    @Test("Search matches title, host and folder")
    func search() async throws {
        let store = makeStore()
        await store.merge([
            Bookmark(url: try url("https://a.com"), title: "Design notes", folderPath: ["Work"]),
            Bookmark(url: try url("https://b.com"), title: "Recipes", folderPath: ["Home"])
        ])
        #expect(await store.search("design", limit: 5).count == 1)
        #expect(await store.search("work", limit: 5).count == 1)
        #expect(await store.search("b.com", limit: 5).count == 1)
    }

    @Test("A missing file behaves as an empty store")
    func missingFile() async {
        #expect(await makeStore().all().isEmpty)
    }
}
