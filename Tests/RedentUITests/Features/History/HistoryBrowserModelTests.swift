import Foundation
import RedentKit
import Testing
@testable import RedentUI

private actor ListedHistoryStore: HistoryStoring {
    private var entries: [HistoryEntry]
    private(set) var deleted: [UUID] = []

    init(_ entries: [HistoryEntry]) { self.entries = entries }

    func record(url: URL, title: String, at date: Date) async {}
    func search(_ query: String, limit: Int) async -> [HistoryEntry] { entries }
    func recent(limit: Int) async -> [HistoryEntry] { entries }
    func mostVisited(limit: Int) async -> [HistoryEntry] { [] }
    func merge(_ entries: [HistoryEntry]) async {}
    func delete(_ id: UUID) async {
        deleted.append(id)
        entries.removeAll { $0.id == id }
    }
    func clearAll() async {}
    func query(_ request: HistoryQuery) async -> [HistoryEntry] { entries }
    func clear(domain: String, containerID: UUID?) async {}
}

@MainActor
@Suite("History browser")
struct HistoryBrowserModelTests {
    private func entry(_ path: String) -> HistoryEntry {
        HistoryEntry(url: URL(string: "https://example.com/\(path)") ?? URL(fileURLWithPath: "/"))
    }

    private func loaded(_ entries: [HistoryEntry]) async -> (HistoryBrowserModel, ListedHistoryStore) {
        let store = ListedHistoryStore(entries)
        let model = HistoryBrowserModel(history: store)
        await model.load()
        return (model, store)
    }

    @Test("Arrow keys start at the top and stop at either end")
    func movesSelection() async {
        let items = [entry("a"), entry("b"), entry("c")]
        let (model, _) = await loaded(items)
        model.moveSelection(by: 1)
        #expect(model.selectedID == items[0].id)
        model.moveSelection(by: 5)
        #expect(model.selectedID == items[2].id)
        model.moveSelection(by: -9)
        #expect(model.selectedID == items[0].id)
    }

    @Test("Deleting the selected page selects the next one, and reaches the store")
    func deleteKeepsPlace() async {
        let items = [entry("a"), entry("b"), entry("c")]
        let (model, store) = await loaded(items)
        model.selectedID = items[1].id
        await model.delete(items[1])
        #expect(model.entries.map(\.id) == [items[0].id, items[2].id])
        #expect(model.selectedID == items[2].id)
        #expect(await store.deleted == [items[1].id])
    }

    @Test("Searching shows one block of best matches instead of days")
    func searchIsOneSection() async {
        let (model, _) = await loaded([entry("a"), entry("b")])
        model.query = "  exa "
        #expect(model.sections().map(\.title) == ["Best Matches"])
    }
}
