import Foundation
import RedentKit
import Testing
@testable import RedentVault

@Suite("Per-Space visit leaderboard")
struct SpaceLeaderboardTests {
    private let work = UUID()
    private let personal = UUID()

    private func makeStore() -> SQLiteHistoryStore {
        let url = FileManager.default.temporaryDirectory
            .appending(path: "redent-leaderboard-\(UUID().uuidString).sqlite")
        return SQLiteHistoryStore(fileURL: url)
    }

    private func visit(_ text: String, times: Int, in spaceID: UUID, store: SQLiteHistoryStore) async throws {
        let url = try #require(URL(string: text))
        for _ in 0..<times {
            let context = HistoryVisitContext(navigationID: UUID(), spaceID: spaceID)
            await store.record(HistoryVisit(url: url, title: "", context: context))
        }
    }

    private func seeded() async throws -> SQLiteHistoryStore {
        let store = makeStore()
        try await visit("https://app.elogy.io/", times: 3, in: work, store: store)
        try await visit("https://app.netflix.com/", times: 12, in: personal, store: store)
        return store
    }

    @Test("a Space's most-visited site leads, even when it loses globally")
    func spaceLeaderFirst() async throws {
        let store = try await seeded()
        #expect(await store.search("app", limit: 5).first?.url.host() == "app.netflix.com")
        let atWork = await store.search("app", in: work, limit: 5)
        #expect(atWork.first?.url.host() == "app.elogy.io")
        let atHome = await store.search("app", in: personal, limit: 5)
        #expect(atHome.first?.url.host() == "app.netflix.com")
    }

    @Test("other history still fills the list, once per page")
    func fillsWithoutDuplicates() async throws {
        let store = try await seeded()
        let atWork = await store.search("app", in: work, limit: 5)
        #expect(atWork.map { $0.url.host() } == ["app.elogy.io", "app.netflix.com"])
    }
}
