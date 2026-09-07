import Foundation
import RedentKit
import Testing
@testable import RedentUI

@Suite("Command Bar")
@MainActor
struct CommandBarModelTests {
    @Test("Mixed sources keep entity identity and select an existing tab")
    func mixedSources() async throws {
        let page = try #require(URL(string: "https://swift.org"))
        let tabID = UUID()
        let tab = CommandTabContext(id: tabID, title: "Swift", values: .init(url: page))
        let context = CommandBarContext(tabs: [tab])
        let history = TestHistoryStore([HistoryEntry(url: page, title: "Swift history")])
        let bookmarks = TestBookmarkStore([Bookmark(url: page, title: "Swift bookmark")])
        let model = makeModel(history: history, bookmarks: bookmarks, context: context)

        model.query = "swift"
        await settle(model)

        #expect(model.rows.contains { $0.source == .tab && $0.action == .focusTab(tabID) })
        #expect(!model.rows.contains { $0.source == .history })
        #expect(!model.rows.contains { $0.source == .bookmark })
    }

    @Test("A slower result for an old query cannot replace the new query")
    func staleResponse() async throws {
        let history = DelayedHistoryStore()
        let model = makeModel(history: history, bookmarks: TestBookmarkStore())
        model.query = "old"
        await Task.yield()
        model.query = "new"
        await settle(model)

        #expect(model.rows.contains { $0.title == "new result" })
        #expect(!model.rows.contains { $0.title == "old result" })
    }

    @Test("A result targeting a deleted tab is rejected before dispatch")
    func deletedTarget() async throws {
        let tabID = UUID()
        let context = CommandBarContext(tabs: [CommandTabContext(id: tabID, title: "Tab")])
        let model = makeModel(history: TestHistoryStore(), bookmarks: TestBookmarkStore(), context: context)
        let sink = ActionSink()
        model.onExecute = { sink.actions.append($0) }
        model.query = "tab"
        await settle(model)
        let row = try #require(model.rows.first { $0.source == .tab })

        model.updateContext(.init())
        await model.execute(row)

        #expect(sink.actions.isEmpty)
    }

    private func settle(_ model: CommandBarModel) async {
        await model.searchInFlight?.value
    }

    private func makeModel(
        history: any HistoryStoring,
        bookmarks: any BookmarkStoring,
        context: CommandBarContext = .init()
    ) -> CommandBarModel {
        var configuration = CommandBarModel.Configuration(history: history, bookmarks: bookmarks)
        configuration.context = context
        return CommandBarModel(configuration: configuration)
    }
}

@MainActor
private final class ActionSink {
    var actions: [BrowserAction] = []
}

private struct TestHistoryStore: HistoryStoring {
    let entries: [HistoryEntry]

    init(_ entries: [HistoryEntry] = []) { self.entries = entries }
    func record(url: URL, title: String, at date: Date) async {}
    func search(_ query: String, limit: Int) async -> [HistoryEntry] {
        entries.filter { $0.displayTitle.localizedCaseInsensitiveContains(query) }
    }
    func recent(limit: Int) async -> [HistoryEntry] { Array(entries.prefix(limit)) }
    func mostVisited(limit: Int) async -> [HistoryEntry] { Array(entries.prefix(limit)) }
    func merge(_ entries: [HistoryEntry]) async {}
    func delete(_ id: UUID) async {}
    func clearAll() async {}
}

private struct TestBookmarkStore: BookmarkStoring {
    let entries: [Bookmark]

    init(_ entries: [Bookmark] = []) { self.entries = entries }
    func all() async -> [Bookmark] { entries }
    func favorites() async -> [Bookmark] { entries.filter(\.isFavorite) }
    func search(_ query: String, limit: Int) async -> [Bookmark] {
        entries.filter { $0.displayTitle.localizedCaseInsensitiveContains(query) }
    }
    func bookmark(for url: URL) async -> Bookmark? { entries.first { $0.url == url } }
    func save(_ bookmark: Bookmark) async {}
    func merge(_ bookmarks: [Bookmark]) async -> Int { 0 }
    func delete(_ id: UUID) async {}
}

private actor DelayedHistoryStore: HistoryStoring {
    func record(url: URL, title: String, at date: Date) async {}
    func search(_ query: String, limit: Int) async -> [HistoryEntry] {
        try? await Task.sleep(for: .milliseconds(query == "old" ? 220 : 5))
        guard let url = URL(string: "https://\(query).example") else { return [] }
        return [HistoryEntry(url: url, title: "\(query) result")]
    }
    func recent(limit: Int) async -> [HistoryEntry] { [] }
    func mostVisited(limit: Int) async -> [HistoryEntry] { [] }
    func merge(_ entries: [HistoryEntry]) async {}
    func delete(_ id: UUID) async {}
    func clearAll() async {}
}
