import Foundation
import Testing
@testable import RedentKit
@testable import RedentUI

@Suite("Visit recorder")
struct VisitRecorderTests {
    private actor CapturingHistory: HistoryStoring {
        private(set) var visits: [URL] = []

        func record(url: URL, title: String, at date: Date) async { visits.append(url) }
        func search(_ query: String, limit: Int) async -> [HistoryEntry] { [] }
        func recent(limit: Int) async -> [HistoryEntry] { [] }
        func mostVisited(limit: Int) async -> [HistoryEntry] { [] }
        func merge(_ entries: [HistoryEntry]) async {}
        func delete(_ id: UUID) async {}
        func clearAll() async {}
    }

    @Test("Sensitive domains are not written to history")
    @MainActor
    func skipsSensitiveDomain() async throws {
        let history = CapturingHistory()
        let recorder = VisitRecorder(history: history)
        let url = try #require(URL(string: "https://online.chase.com/home"))
        var snapshot = TabSnapshot(url: url, title: "Chase")
        snapshot.lifespan = .normal
        let policy = SensitiveSitePolicy(customDomains: ["chase.com"])
        recorder.record(snapshot, navigationID: UUID(), policy: policy)
        try await Task.sleep(for: .milliseconds(20))
        let recorded = await history.visits
        #expect(recorded.isEmpty)
    }

    @Test("Other sites are still written to history")
    @MainActor
    func recordsOrdinarySite() async throws {
        let history = CapturingHistory()
        let recorder = VisitRecorder(history: history)
        let url = try #require(URL(string: "https://news.example/"))
        let policy = SensitiveSitePolicy(excludeBankingAndHealth: true, customDomains: ["chase.com"])
        recorder.record(TabSnapshot(url: url, title: "News"), navigationID: UUID(), policy: policy)
        for _ in 0..<100 where await history.visits.isEmpty { try await Task.sleep(for: .milliseconds(10)) }
        #expect(await history.visits == [url])
    }

    @Test("Temporary tabs stay excluded")
    @MainActor
    func temporaryStillSkipped() async throws {
        let history = CapturingHistory()
        let recorder = VisitRecorder(history: history)
        let url = try #require(URL(string: "https://example.com/"))
        var snapshot = TabSnapshot(url: url, title: "Example")
        snapshot.lifespan = .temporary(sessionID: UUID(), expiresAt: nil, cleanupOnClose: true)
        recorder.record(snapshot, navigationID: UUID(), policy: SensitiveSitePolicy())
        try await Task.sleep(for: .milliseconds(20))
        let recorded = await history.visits
        #expect(recorded.isEmpty)
    }
}
