import Foundation
import RedentKit
import Testing
@testable import RedentUI

@Suite("Address suggestions ownership")
@MainActor
struct AddressSuggestionsModelTests {
    private func makeModel() -> AddressSuggestionsModel {
        AddressSuggestionsModel(engine: SuggestionEngine(
            history: EmptyHistoryStore(),
            bookmarks: EmptyBookmarkStore()
        ))
    }

    /// Awaits the query the model actually has in flight. Sleeping for "long
    /// enough" instead made this suite fail whenever the machine was busy.
    private func settle(_ model: AddressSuggestionsModel) async {
        await model.queryInFlight?.value
    }

    @Test("A list opened by one field does not appear under the other")
    func openListBelongsToOneFieldOnly() async throws {
        let model = makeModel()
        model.update(query: "example.com", from: .newTab, searchEngine: .duckduckgo)
        await settle(model)

        #expect(!model.rows.isEmpty)
        #expect(model.isOpen(for: .newTab))
        #expect(!model.isOpen(for: .addressBar))
    }

    @Test("Typing in the other field hands the list over")
    func typingElsewhereTakesOwnership() async throws {
        let model = makeModel()
        model.update(query: "example.com", from: .newTab, searchEngine: .duckduckgo)
        await settle(model)
        model.update(query: "swift.org", from: .addressBar, searchEngine: .duckduckgo)
        await settle(model)

        #expect(model.isOpen(for: .addressBar))
        #expect(!model.isOpen(for: .newTab))
    }

    @Test("A field losing focus leaves the other field's list standing")
    func scopedCloseIgnoresForeignLists() async throws {
        let model = makeModel()
        model.update(query: "example.com", from: .newTab, searchEngine: .duckduckgo)
        await settle(model)

        model.close(from: .addressBar)
        #expect(model.isOpen(for: .newTab))

        model.close(from: .newTab)
        #expect(!model.isOpen(for: .newTab))
        #expect(model.rows.isEmpty)
    }

    @Test("A blur cancels a query that has not landed yet")
    func scopedCloseCancelsOwnPendingQuery() async throws {
        let model = makeModel()
        model.update(query: "example.com", from: .addressBar, searchEngine: .duckduckgo)
        model.close(from: .addressBar)
        await settle(model)

        #expect(!model.isOpen(for: .addressBar))
        #expect(model.rows.isEmpty)
    }

    @Test("Vertical arrows walk the open list and wrap")
    func arrowsWalkAndWrap() async throws {
        let model = makeModel()
        model.update(query: "example.com", from: .newTab, searchEngine: .duckduckgo)
        await settle(model)

        let count = model.rows.count
        #expect(count >= 2)
        #expect(model.highlighted == 0)

        model.moveHighlight(by: 1)
        #expect(model.highlighted == 1)

        model.moveHighlight(by: -1)
        #expect(model.highlighted == 0)

        model.moveHighlight(by: -1)
        #expect(model.highlighted == count - 1)
    }

    @Test("Arrows do nothing when no list is open")
    func arrowsIgnoredWhileClosed() {
        let model = makeModel()
        model.moveHighlight(by: 1)
        #expect(model.highlighted == nil)
    }
}

private struct EmptyHistoryStore: HistoryStoring {
    func record(url: URL, title: String, at date: Date) async {}
    func search(_ query: String, limit: Int) async -> [HistoryEntry] { [] }
    func recent(limit: Int) async -> [HistoryEntry] { [] }
    func mostVisited(limit: Int) async -> [HistoryEntry] { [] }
    func merge(_ entries: [HistoryEntry]) async {}
    func delete(_ id: UUID) async {}
    func clearAll() async {}
}

private struct EmptyBookmarkStore: BookmarkStoring {
    func all() async -> [Bookmark] { [] }
    func favorites() async -> [Bookmark] { [] }
    func search(_ query: String, limit: Int) async -> [Bookmark] { [] }
    func bookmark(for url: URL) async -> Bookmark? { nil }
    func save(_ bookmark: Bookmark) async {}
    func merge(_ bookmarks: [Bookmark]) async -> Int { 0 }
    func delete(_ id: UUID) async {}
}
