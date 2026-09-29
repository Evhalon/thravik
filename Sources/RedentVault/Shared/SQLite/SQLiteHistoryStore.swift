import Foundation
import RedentKit

/// SQLite-backed `HistoryStoring`. A thin, `Sendable` façade over the
/// actor that actually owns the connection and does the I/O off-main.
public struct SQLiteHistoryStore: HistoryStoring {
    private let database: HistoryDatabase

    /// - Parameter fileURL: defaults to `~/Library/Application Support/Redent/history.sqlite`.
    public init(fileURL: URL? = nil) {
        let resolvedURL = fileURL ?? RedentSupportDirectory.defaultFileURL(named: "history.sqlite")
        database = HistoryDatabase(fileURL: resolvedURL)
    }

    public func record(url: URL, title: String, at date: Date) async {
        await database.record(url: url, title: title, at: date)
    }

    public func record(_ visit: HistoryVisit) async {
        await database.record(visit)
    }

    public func search(_ query: String, limit: Int) async -> [HistoryEntry] {
        await database.search(query, limit: limit)
    }

    public func query(_ request: HistoryQuery) async -> [HistoryEntry] {
        await database.query(request)
    }

    public func recent(limit: Int) async -> [HistoryEntry] {
        await database.recent(limit: limit)
    }

    public func mostVisited(limit: Int) async -> [HistoryEntry] {
        await database.mostVisited(limit: limit)
    }

    public func merge(_ entries: [HistoryEntry]) async {
        await database.merge(entries)
    }

    public func delete(_ id: UUID) async {
        await database.delete(id)
    }

    public func clearAll() async {
        await database.clearAll()
    }

    public func clear(domain: String, containerID: UUID?) async {
        await database.clear(domain: domain, containerID: containerID)
    }
}
