import Foundation
import RedentKit

/// Bulk import of up to ~20,000 rows: one transaction, one prepared
/// statement reset-and-rebound per row, so a full-history import doesn't
/// pay prepare/plan cost twenty thousand times.
enum HistoryMerge {
    private static let sql = """
    INSERT INTO visits (\(HistorySchema.columns), unknown_count) VALUES (?, ?, ?, ?, ?, ?, ?)
    ON CONFLICT(url) DO UPDATE SET
      visit_count = MAX(visit_count, excluded.visit_count),
      last_visit = MAX(last_visit, excluded.last_visit),
      unknown_count = MAX(unknown_count, excluded.unknown_count)
    """

    static func run(_ entries: [HistoryEntry], on connection: SQLiteConnection) {
        do {
            try connection.execute("BEGIN TRANSACTION")
            let statement = try connection.prepare(sql)
            for entry in entries {
                bindAndStep(entry, statement: statement)
            }
            try connection.execute("COMMIT")
        } catch {
            try? connection.execute("ROLLBACK")
        }
    }

    private static func bindAndStep(_ entry: HistoryEntry, statement: SQLiteStatement) {
        guard let origin = Origin(url: entry.url), let storableURL = HistoryRow.storableURL(entry.url) else { return }
        statement.bind(HistoryRow.bindings(
            id: entry.id, url: storableURL, host: origin.host,
            title: entry.title, visitCount: entry.visitCount, lastVisit: entry.lastVisit
        ) + [.int(Int64(entry.visitCount))])
        statement.step()
        statement.reset()
    }
}
