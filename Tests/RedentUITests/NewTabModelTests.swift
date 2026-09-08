import Foundation
import RedentKit
import Testing
@testable import RedentUI

/// The new-tab grid belongs to the Space it is opened in.
@MainActor
@Suite("Frequently visited is per Space")
struct NewTabModelTests {
    private func page(_ value: String) throws -> URL { try #require(URL(string: value)) }

    @Test("Only the sites visited in this Space are suggested")
    func frequentIsScopedToSpace() async throws {
        let history = SpacedHistoryStore(bySpace: [
            BrowserSpace.workID: [HistoryEntry(url: try page("https://tracker.work/"))],
            BrowserSpace.personalID: [HistoryEntry(url: try page("https://forum.home/"))]
        ])
        let model = NewTabModel(history: history, bookmarks: EmptyBookmarkStore())

        await model.load(in: BrowserSpace.workID)
        #expect(model.tiles.map(\.host) == ["tracker.work"])

        await model.load(in: BrowserSpace.personalID)
        #expect(model.tiles.map(\.host) == ["forum.home"])
    }

    @Test("A Space with no browsing of its own still shows something")
    func emptySpaceFallsBackToEverySpace() async throws {
        let history = SpacedHistoryStore(
            bySpace: [BrowserSpace.workID: [HistoryEntry(url: try page("https://tracker.work/"))]]
        )
        let model = NewTabModel(history: history, bookmarks: EmptyBookmarkStore())

        await model.load(in: BrowserSpace.travelID)
        #expect(model.tiles.map(\.host) == ["tracker.work"])
        #expect(model.isBare == false)
    }
}

/// History that answers scoped queries the way the SQLite store does, and
/// falls back to every Space for an unscoped `mostVisited`.
private struct SpacedHistoryStore: HistoryStoring {
    let bySpace: [UUID: [HistoryEntry]]

    func query(_ request: HistoryQuery) async -> [HistoryEntry] {
        guard let spaceID = request.scope.spaceID else { return await mostVisited(limit: request.limit) }
        return Array((bySpace[spaceID] ?? []).prefix(request.limit))
    }

    func mostVisited(limit: Int) async -> [HistoryEntry] {
        Array(bySpace.values.flatMap { $0 }.prefix(limit))
    }

    func record(url: URL, title: String, at date: Date) async {}
    func search(_ query: String, limit: Int) async -> [HistoryEntry] { [] }
    func recent(limit: Int) async -> [HistoryEntry] { [] }
    func merge(_ entries: [HistoryEntry]) async {}
    func delete(_ id: UUID) async {}
    func clearAll() async {}
}

private struct EmptyBookmarkStore: BookmarkStoring {
    func all(in spaceID: UUID?) async -> [Bookmark] { [] }
    func favorites(in spaceID: UUID?) async -> [Bookmark] { [] }
    func search(_ query: String, in spaceID: UUID?, limit: Int) async -> [Bookmark] { [] }
    func bookmark(for url: URL, in spaceID: UUID?) async -> Bookmark? { nil }
    func save(_ bookmark: Bookmark) async {}
    func merge(_ bookmarks: [Bookmark]) async -> Int { 0 }
    func delete(_ id: UUID) async {}
}
