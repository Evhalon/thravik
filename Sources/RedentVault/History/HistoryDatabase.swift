import Foundation
import RedentKit

/// Owns the SQLite connection and keeps history I/O off the main actor.
actor HistoryDatabase {
    let connection: SQLiteConnection?

    init(fileURL: URL) {
        connection = Self.open(at: fileURL)
    }

    private static func open(at fileURL: URL) -> SQLiteConnection? {
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true
            )
            let connection = try SQLiteConnection(path: fileURL.path)
            try connection.execute(HistorySchema.pragmas)
            try HistoryMigration.run(on: connection)
            return connection
        } catch {
            return nil
        }
    }

    func record(url: URL, title: String, at date: Date) {
        record(HistoryVisit(url: url, title: title, date: date))
    }

    func merge(_ entries: [HistoryEntry]) {
        guard let connection, !entries.isEmpty else { return }
        HistoryMerge.run(entries, on: connection)
    }

    func delete(_ id: UUID) {
        guard let connection else { return }
        do {
            var url: String?
            try connection.query(
                "SELECT url FROM visits WHERE id = ?", bindings: [.text(id.uuidString)]
            ) { statement in url = statement.text(0) }
            guard let url else { return }
            try connection.run("DELETE FROM contextual_visits WHERE url = ?", bindings: [.text(url)])
            try connection.run("DELETE FROM visits WHERE id = ?", bindings: [.text(id.uuidString)])
        } catch {}
    }

    func clearAll() {
        guard let connection else { return }
        try? connection.run("DELETE FROM contextual_visits")
        try? connection.run("DELETE FROM visits")
    }
}
