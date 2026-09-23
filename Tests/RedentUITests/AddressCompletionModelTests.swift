import Foundation
import RedentKit
import Testing
@testable import RedentUI

@Suite("Address suggestions completion")
@MainActor
struct AddressSuggestionsCompletionTests {
    private let context = SuggestionContext(searchEngine: .duckduckgo)

    private func makeModel() throws -> AddressSuggestionsModel {
        let page = try #require(URL(string: "https://github.com/apple"))
        return AddressSuggestionsModel(engine: SuggestionEngine(
            history: HostHistoryStore(entries: [HistoryEntry(url: page, title: "Apple")]),
            bookmarks: InertBookmarkStore()
        ))
    }

    private func type(_ text: String, into model: AddressSuggestionsModel) async {
        model.update(query: text, from: .addressBar, context: context)
        await model.queryInFlight?.value
    }

    @Test("Return follows the completion the field shows")
    func submissionFollowsCompletion() async throws {
        let model = try makeModel()
        await type("git", into: model)

        #expect(model.completion?.text == "github.com")
        #expect(model.submission(for: "github.com")?.url.absoluteString == "https://github.com")
        #expect(model.submission(for: "git") == nil)
    }

    @Test("The field echoing its completion does not re-run the query")
    func echoIsIgnored() async throws {
        let model = try makeModel()
        await type("git", into: model)
        let rowsBefore = model.rows
        model.update(query: "github.com", from: .addressBar, context: context)
        await model.queryInFlight?.value

        #expect(model.query == "git")
        #expect(model.rows == rowsBefore)
        #expect(model.completion?.typed == "git")
    }

    @Test("Backspace clears the completion instead of restoring it")
    func deletingDoesNotComplete() async throws {
        let model = try makeModel()
        await type("gith", into: model)
        await type("git", into: model)

        #expect(model.completion == nil)
        #expect(model.rows.first?.kind == .search)
    }
}

private struct HostHistoryStore: HistoryStoring {
    let entries: [HistoryEntry]
    func record(url: URL, title: String, at date: Date) async {}
    func search(_ query: String, limit: Int) async -> [HistoryEntry] {
        entries.filter { $0.url.host()?.contains(query.lowercased()) ?? false }
    }
    func recent(limit: Int) async -> [HistoryEntry] { [] }
    func mostVisited(limit: Int) async -> [HistoryEntry] { [] }
    func merge(_ entries: [HistoryEntry]) async {}
    func delete(_ id: UUID) async {}
    func clearAll() async {}
}
