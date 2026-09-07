import Foundation
import RedentKit
import Testing
@testable import RedentVault

@Suite("History storage and ranking")
struct HistoryStoreTests {
    private func makeStore() -> SQLiteHistoryStore {
        let url = FileManager.default.temporaryDirectory
            .appending(path: "redent-test-\(UUID().uuidString).sqlite")
        return SQLiteHistoryStore(fileURL: url)
    }

    private func url(_ text: String) throws -> URL {
        try #require(URL(string: text))
    }

    @Test("Revisiting a page counts up rather than duplicating it")
    func repeatVisit() async throws {
        let store = makeStore()
        let page = try url("https://example.com/docs")
        await store.record(url: page, title: "Docs", at: .now)
        await store.record(url: page, title: "Docs", at: .now)
        let found = await store.search("example", limit: 10)
        #expect(found.count == 1)
        #expect(found.first?.visitCount == 2)
    }

    @Test("Query strings never reach storage")
    func stripsQuery() async throws {
        let store = makeStore()
        await store.record(url: try url("https://x.com/a?token=hunter2#frag"), title: "A", at: .now)
        let found = await store.search("x.com", limit: 10)
        #expect(found.count == 1)
        let stored = try #require(found.first?.url.absoluteString)
        #expect(!stored.contains("hunter2"))
        #expect(!stored.contains("#"))
        #expect(stored == "https://x.com/a")
    }

    @Test("Non-web schemes are not recorded", arguments: [
        "file:///Users/me/secret.txt", "data:text/html,hi", "about:blank"
    ])
    func ignoresNonWeb(_ raw: String) async throws {
        let store = makeStore()
        await store.record(url: try url(raw), title: "x", at: .now)
        #expect(await store.recent(limit: 10).isEmpty)
    }

    @Test("A host-prefix match outranks a title match")
    func rankingPrefersHost() async throws {
        let store = makeStore()
        await store.record(url: try url("https://github.com/"), title: "Home", at: .now)
        await store.record(url: try url("https://example.com/a"), title: "github tips", at: .now)
        let found = await store.search("github", limit: 5)
        #expect(found.first?.origin?.host == "github.com")
    }

    @Test("The new-tab grid shows one page per site")
    func mostVisitedCollapsesHosts() async throws {
        let store = makeStore()
        for path in ["a", "b", "c"] {
            await store.record(url: try url("https://news.com/\(path)"), title: path, at: .now)
        }
        await store.record(url: try url("https://other.com/x"), title: "x", at: .now)
        let top = await store.mostVisited(limit: 10)
        #expect(Set(top.compactMap(\.origin?.host)).count == top.count)
        #expect(top.count == 2)
    }

    @Test("Merging keeps the higher visit count and the later visit")
    func mergeKeepsStrongest() async throws {
        let store = makeStore()
        let page = try url("https://a.com/p")
        let old = Date(timeIntervalSince1970: 1_600_000_000)
        let recent = Date(timeIntervalSince1970: 1_700_000_000)
        await store.merge([HistoryEntry(url: page, title: "P", visitCount: 9, lastVisit: recent)])
        await store.merge([HistoryEntry(url: page, title: "P", visitCount: 2, lastVisit: old)])
        let found = await store.search("a.com", limit: 5)
        #expect(found.first?.visitCount == 9)
        #expect(found.first?.lastVisit == recent)
    }
}
