import Foundation
import Observation
import RedentKit

/// Loads contextual history for the browser's dedicated history surface.
@MainActor @Observable
public final class HistoryBrowserModel {
    public private(set) var entries: [HistoryEntry] = []
    public var query = ""
    public var spaceID: UUID?
    public var containerID: UUID?
    public private(set) var isLoading = false

    private let history: any HistoryStoring

    public init(
        history: any HistoryStoring, spaceID: UUID? = nil, containerID: UUID? = nil
    ) {
        self.history = history
        self.spaceID = spaceID
        self.containerID = containerID
    }

    public func load() async {
        isLoading = true
        defer { isLoading = false }
        entries = await history.query(request)
    }

    public func delete(_ entry: HistoryEntry) async {
        await history.delete(entry.id)
        await load()
    }

    public func clear(domain: String) async {
        await history.clear(domain: domain, containerID: containerID)
        await load()
    }

    private var request: HistoryQuery {
        HistoryQuery(
            text: query,
            scope: HistoryScope(spaceID: spaceID, containerID: containerID),
            limit: 200,
            sort: query.isEmpty ? .recent : .relevance
        )
    }
}
