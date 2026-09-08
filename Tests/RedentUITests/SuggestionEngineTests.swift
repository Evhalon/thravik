import Foundation
import RedentKit
import Testing
@testable import RedentUI

@Suite("Address bar suggestions")
struct SuggestionEngineTests {
    private func url(_ text: String) throws -> URL { try #require(URL(string: text)) }

    private func makeEngine(
        history: [HistoryEntry] = [],
        bookmarks: [Bookmark] = []
    ) -> SuggestionEngine {
        SuggestionEngine(
            history: FakeHistoryStore(history),
            bookmarks: FakeBookmarkStore(bookmarks)
        )
    }

    @Test("An empty query keeps the dropdown closed", arguments: ["", "   "])
    func emptyQuery(_ query: String) async {
        #expect(await makeEngine().suggestions(for: query, engine: .duckduckgo, spaceID: nil).isEmpty)
    }

    @Test("Typing a host offers to open it directly, first")
    func directURLFirst() async {
        let rows = await makeEngine().suggestions(for: "example.com", engine: .duckduckgo, spaceID: nil)
        #expect(rows.first?.kind == .directURL)
    }

    @Test("There is always exactly one search row, and it is last")
    func searchRowIsLast() async throws {
        let rows = await makeEngine(
            history: [HistoryEntry(url: try url("https://swift.org"), title: "Swift")]
        ).suggestions(for: "swift", engine: .duckduckgo, spaceID: nil)
        #expect(rows.filter { $0.kind == .search }.count == 1)
        #expect(rows.last?.kind == .search)
    }

    @Test("A bookmarked page is not repeated as a history row")
    func dedupesAcrossSources() async throws {
        let page = try url("https://swift.org")
        let rows = await makeEngine(
            history: [HistoryEntry(url: page, title: "Swift")],
            bookmarks: [Bookmark(url: page, title: "Swift")]
        ).suggestions(for: "swift", engine: .duckduckgo, spaceID: nil)
        #expect(rows.filter { $0.url == page }.count == 1)
        #expect(rows.contains { $0.kind == .bookmark })
    }

    @Test("The limit is respected even with plenty of matches")
    func respectsLimit() async throws {
        let entries = try (0..<20).map {
            HistoryEntry(url: try url("https://site\($0).com"), title: "site \($0)")
        }
        let rows = await makeEngine(history: entries)
            .suggestions(for: "site", engine: .duckduckgo, spaceID: nil, limit: 6)
        #expect(rows.count <= 6)
    }
}

private struct FakeHistoryStore: HistoryStoring {
    let entries: [HistoryEntry]
    init(_ entries: [HistoryEntry]) { self.entries = entries }

    func record(url: URL, title: String, at date: Date) async {}
    func search(_ query: String, limit: Int) async -> [HistoryEntry] {
        Array(entries.filter { $0.displayTitle.lowercased().contains(query.lowercased())
            || ($0.origin?.host.contains(query.lowercased()) ?? false) }.prefix(limit))
    }
    func recent(limit: Int) async -> [HistoryEntry] { Array(entries.prefix(limit)) }
    func mostVisited(limit: Int) async -> [HistoryEntry] { Array(entries.prefix(limit)) }
    func merge(_ entries: [HistoryEntry]) async {}
    func delete(_ id: UUID) async {}
    func clearAll() async {}
}

private struct FakeBookmarkStore: BookmarkStoring {
    let items: [Bookmark]
    init(_ items: [Bookmark]) { self.items = items }

    func all(in spaceID: UUID?) async -> [Bookmark] { scoped(spaceID) }
    func favorites(in spaceID: UUID?) async -> [Bookmark] { scoped(spaceID).filter(\.isFavorite) }
    func search(_ query: String, in spaceID: UUID?, limit: Int) async -> [Bookmark] {
        Array(scoped(spaceID).filter { $0.displayTitle.lowercased().contains(query.lowercased()) }.prefix(limit))
    }
    func bookmark(for url: URL, in spaceID: UUID?) async -> Bookmark? {
        scoped(spaceID).first { $0.url == url }
    }
    private func scoped(_ spaceID: UUID?) -> [Bookmark] {
        guard let spaceID else { return items }
        return items.filter { $0.spaceID == spaceID }
    }
    func save(_ bookmark: Bookmark) async {}
    func merge(_ bookmarks: [Bookmark]) async -> Int { 0 }
    func delete(_ id: UUID) async {}
}
