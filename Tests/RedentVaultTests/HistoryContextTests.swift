import Foundation
import RedentKit
import Testing
@testable import RedentVault

@Suite("Contextual history")
struct HistoryContextTests {
    private func makeStore() -> SQLiteHistoryStore {
        let url = FileManager.default.temporaryDirectory
            .appending(path: "redent-context-\(UUID().uuidString).sqlite")
        return SQLiteHistoryStore(fileURL: url)
    }

    private func page(_ value: String) throws -> URL { try #require(URL(string: value)) }

    private func legacyDatabase() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appending(path: "redent-legacy-\(UUID().uuidString).sqlite")
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/sqlite3")
        let legacyID = UUID().uuidString
        process.arguments = [url.path, """
            CREATE TABLE visits (id TEXT PRIMARY KEY, url TEXT NOT NULL UNIQUE,
            host TEXT NOT NULL, title TEXT NOT NULL, visit_count INTEGER NOT NULL,
            last_visit REAL NOT NULL);
            INSERT INTO visits VALUES ('\(legacyID)', 'https://legacy.example/a',
            'legacy.example', 'Legacy', 5, 1700000000);
            """]
        try process.run()
        process.waitUntilExit()
        #expect(process.terminationStatus == 0)
        return url
    }

    @Test("migration preserves legacy counts as unknown context")
    func migratesAggregates() async throws {
        let url = try legacyDatabase()
        let store = SQLiteHistoryStore(fileURL: url)
        await store.record(HistoryVisit(
            url: try page("https://legacy.example/a"),
            context: HistoryVisitContext(navigationID: UUID(), spaceID: UUID())
        ))
        let result = await store.search("legacy", limit: 5)
        #expect(result.first?.visitCount == 6)
    }

    @Test("same URL keeps separate Space context and navigation deduplication")
    func contextualVisits() async throws {
        let store = makeStore()
        let url = try page("https://example.com/docs")
        let first = UUID()
        let work = UUID()
        let research = UUID()
        let context = HistoryVisitContext(navigationID: first, spaceID: work)
        await store.record(HistoryVisit(url: url, title: "Docs", context: context))
        await store.record(HistoryVisit(url: url, title: "Docs", context: context))
        await store.record(HistoryVisit(
            url: url, title: "Docs", context: HistoryVisitContext(navigationID: UUID(), spaceID: research)
        ))

        let workResults = await store.query(HistoryQuery(scope: HistoryScope(spaceID: work), limit: 5))
        let researchResults = await store.query(HistoryQuery(scope: HistoryScope(spaceID: research), limit: 5))
        #expect(workResults.first?.visitCount == 1)
        #expect(researchResults.first?.visitCount == 1)
        #expect((await store.search("example", limit: 5)).first?.visitCount == 2)
    }

    @Test("a strong match after the old 200 candidate boundary still wins")
    func searchesAllCandidates() async throws {
        let store = makeStore()
        for index in 0..<205 {
            await store.record(
                HistoryVisit(
                    url: try page("https://site\(index).com/page"), title: "needle page",
                    date: Date(timeIntervalSince1970: Double(index))
                )
            )
        }
        let strong = try page("https://needle.example.com/")
        await store.record(HistoryVisit(url: strong, title: "Home"))
        #expect((await store.search("needle", limit: 1)).first?.url == strong)
    }

    @Test("clearing one Container keeps the other Container")
    func scopedDeletion() async throws {
        let store = makeStore()
        let first = UUID()
        let second = UUID()
        let url = try page("https://example.com/a")
        await store.record(HistoryVisit(
            url: url, context: HistoryVisitContext(navigationID: UUID(), containerID: first)
        ))
        await store.record(HistoryVisit(
            url: url, context: HistoryVisitContext(navigationID: UUID(), containerID: second)
        ))
        await store.clear(domain: "example.com", containerID: first)
        let remaining = await store.query(HistoryQuery(scope: HistoryScope(containerID: second), limit: 5))
        #expect(remaining.count == 1)
        #expect(remaining.first?.visitCount == 1)
        #expect((await store.query(HistoryQuery(scope: HistoryScope(containerID: first), limit: 5))).isEmpty)
    }
}
