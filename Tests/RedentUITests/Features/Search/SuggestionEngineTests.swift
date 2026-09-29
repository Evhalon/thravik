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

    private func rows(
        _ query: String, history: [HistoryEntry] = [], bookmarks: [Bookmark] = [],
        openTabs: [OpenTabCandidate] = []
    ) async -> [AddressSuggestion] {
        await result(query, history: history, bookmarks: bookmarks, openTabs: openTabs).rows
    }

    private func result(
        _ query: String, history: [HistoryEntry] = [], bookmarks: [Bookmark] = [],
        openTabs: [OpenTabCandidate] = []
    ) async -> SuggestionResult {
        await makeEngine(history: history, bookmarks: bookmarks).suggestions(
            for: query, context: SuggestionContext(searchEngine: .duckduckgo, openTabs: openTabs)
        )
    }

    @Test("An empty query keeps the dropdown closed", arguments: ["", "   "])
    func emptyQuery(_ query: String) async {
        #expect(await rows(query).isEmpty)
    }

    @Test("Typing a host offers to open it directly, first")
    func directURLFirst() async {
        #expect(await rows("example.com").first?.kind == .directURL)
    }

    @Test("A query that is not an address leads with the search row")
    func searchLeadsPlainQueries() async throws {
        let found = await rows("swift", history: [HistoryEntry(url: try url("https://docs.swift.org/x"), title: "Swift")])
        #expect(found.first?.kind == .search)
        #expect(found.filter { $0.kind == .search }.count == 1)
    }

    @Test("A known host completes inline, and its row leads")
    func knownHostCompletes() async throws {
        let found = await result("git", history: [HistoryEntry(url: try url("https://github.com/apple"), title: "Apple")])
        #expect(found.completion?.text == "github.com")
        #expect(found.completion?.url == (try url("https://github.com")))
        #expect(found.rows.first?.url == found.completion?.url)
        #expect(found.rows.last?.kind == .search)
    }

    @Test("Deleting asks for no completion")
    func completionCanBeRefused() async throws {
        let found = await makeEngine(history: [HistoryEntry(url: try url("https://github.com"), title: "GitHub")])
            .suggestions(for: "git", context: SuggestionContext(searchEngine: .duckduckgo), allowsCompletion: false)
        #expect(found.completion == nil)
        #expect(found.rows.first?.kind == .search)
    }

    @Test("A matching open tab is offered as a switch, and owns its URL")
    func openTabsSwitch() async throws {
        let page = try url("https://github.com/apple")
        let tab = OpenTabCandidate(id: UUID(), title: "Apple on GitHub", url: page)
        let found = await rows("apple", history: [HistoryEntry(url: page, title: "Apple on GitHub")], openTabs: [tab])
        #expect(found.contains { $0.kind == .openTab && $0.tabID == tab.id })
        #expect(!found.contains { $0.kind == .history && $0.url == page })
    }

    @Test("A bookmarked page is not repeated as a history row")
    func dedupesAcrossSources() async throws {
        let page = try url("https://docs.swift.org/book")
        let found = await rows("swift", history: [HistoryEntry(url: page, title: "Swift")],
                               bookmarks: [Bookmark(url: page, title: "Swift")])
        #expect(found.filter { $0.url == page }.count == 1)
        #expect(found.contains { $0.kind == .bookmark })
    }

    @Test("The limit is respected even with plenty of matches")
    func respectsLimit() async throws {
        let entries = try (0..<20).map {
            HistoryEntry(url: try url("https://site\($0).com"), title: "site \($0)")
        }
        let found = await makeEngine(history: entries).suggestions(
            for: "site", context: SuggestionContext(searchEngine: .duckduckgo), limit: 6
        )
        #expect(found.rows.count <= 6)
        #expect(found.rows.contains { $0.kind == .search })
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
