import Foundation
import RedentKit
import RedentVault
import Testing

struct BookmarkStorageRouterTests {
    @Test func accountProjectionDoesNotMixWithLocalBookmarks() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let local = JSONBookmarkStore(fileURL: directory.appendingPathComponent("local.json"))
        let account = JSONBookmarkStore(fileURL: directory.appendingPathComponent("account.json"))
        let router = BookmarkStorageRouter(local: local)
        let localItem = Bookmark(url: try #require(URL(string: "https://local.example")))
        let cloudItem = Bookmark(url: try #require(URL(string: "https://account.example")))

        await local.save(localItem)
        await router.selectAccountStore(account)
        await router.save(cloudItem)

        #expect(await router.all(in: nil) == [cloudItem])
        #expect(await local.all(in: nil) == [localItem])
        await router.selectAccountStore(nil)
        #expect(await router.all(in: nil) == [localItem])
        await router.selectAccountStore(account)
        #expect(await router.all(in: nil) == [cloudItem])
    }
    @Test func staleAccountPreparationCannotSelectPreviousVault() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let router = BookmarkStorageRouter(local: JSONBookmarkStore(fileURL: directory.appendingPathComponent("local.json")))
        let previous = UUID()
        await router.resetAccountSelection(generation: previous)
        await router.resetAccountSelection(generation: UUID())
        let oldStore = JSONBookmarkStore(fileURL: directory.appendingPathComponent("old.json"))
        #expect(!(await router.selectAccountStore(oldStore, generation: previous)))
    }

}
