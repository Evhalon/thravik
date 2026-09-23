import Foundation
import Observation
import RedentKit

/// Loads contextual history for the browser's dedicated history surface, and
/// owns the keyboard selection that moves through it.
@MainActor @Observable
public final class HistoryBrowserModel {
    public private(set) var entries: [HistoryEntry] = []
    public var query = ""
    public var spaceID: UUID?
    public var containerID: UUID?
    public private(set) var isLoading = false
    public private(set) var hasLoaded = false
    public var selectedID: UUID?

    private let history: any HistoryStoring

    public init(
        history: any HistoryStoring, spaceID: UUID? = nil, containerID: UUID? = nil
    ) {
        self.history = history
        self.spaceID = spaceID
        self.containerID = containerID
    }

    var isSearching: Bool { !query.trimmingCharacters(in: .whitespaces).isEmpty }

    /// Days while browsing; one relevance-ordered block while searching,
    /// because splitting best matches by date would bury the best one.
    func sections(now: Date = .now) -> [HistorySection] {
        guard isSearching else { return HistorySection.byDay(entries, now: now) }
        guard !entries.isEmpty else { return [] }
        return [HistorySection(id: "matches", title: "Best Matches", entries: entries)]
    }

    public func load() async {
        isLoading = true
        defer { isLoading = false; hasLoaded = true }
        entries = await history.query(request)
        if let selectedID, !entries.contains(where: { $0.id == selectedID }) {
            self.selectedID = nil
        }
    }

    /// Drops the row at once and keeps the selection on its neighbour, so
    /// deleting a run of pages with the keyboard never loses its place.
    public func delete(_ entry: HistoryEntry) async {
        guard let index = entries.firstIndex(where: { $0.id == entry.id }) else { return }
        entries.remove(at: index)
        if selectedID == entry.id {
            selectedID = entries.indices.contains(index) ? entries[index].id : entries.last?.id
        }
        await history.delete(entry.id)
    }

    public func clear(domain: String) async {
        await history.clear(domain: domain, containerID: containerID)
        await load()
    }

    var selectedEntry: HistoryEntry? {
        entries.first { $0.id == selectedID }
    }

    /// Moves by `offset` rows, starting from the top when nothing is selected.
    func moveSelection(by offset: Int) {
        guard !entries.isEmpty else { return }
        guard let current = entries.firstIndex(where: { $0.id == selectedID }) else {
            selectedID = offset < 0 ? entries.last?.id : entries.first?.id
            return
        }
        let next = min(max(current + offset, 0), entries.count - 1)
        selectedID = entries[next].id
    }

    private var request: HistoryQuery {
        HistoryQuery(
            text: query.trimmingCharacters(in: .whitespaces),
            scope: HistoryScope(spaceID: spaceID, containerID: containerID),
            limit: 300,
            sort: isSearching ? .relevance : .recent
        )
    }
}
