import Foundation
import RedentKit

/// Reads Chromium's `History` SQLite database into `[HistoryEntry]`.
enum HistoryTableReader {
    private static let query = """
        SELECT url, title, visit_count, last_visit_time FROM urls
        WHERE hidden = 0 AND url NOT LIKE 'chrome%' AND url NOT LIKE 'about:%'
        ORDER BY visit_count DESC LIMIT 20000
        """

    static func read(from databaseURL: URL) throws -> [HistoryEntry] {
        let db = try SQLiteDatabase(readOnlyAt: databaseURL)
        var entries: [HistoryEntry] = []

        try db.query(query) { row in
            guard let urlString = row.text(0), let url = URL(string: urlString),
                  let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https"
            else { return }

            entries.append(
                HistoryEntry(
                    url: url,
                    title: row.text(1) ?? "",
                    visitCount: row.int(2),
                    lastVisit: ChromeEpoch.date(fromMicroseconds: row.int64(3))
                )
            )
        }
        return entries
    }
}
