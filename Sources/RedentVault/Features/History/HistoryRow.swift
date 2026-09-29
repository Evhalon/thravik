import Foundation
import RedentKit

/// Maps between `HistoryEntry` and `visits` table rows.
enum HistoryRow {
    static func entry(from statement: SQLiteStatement) -> HistoryEntry? {
        guard let id = UUID(uuidString: statement.text(0)),
              let url = URL(string: statement.text(1))
        else { return nil }
        return HistoryEntry(
            id: id,
            url: url,
            title: statement.text(3),
            visitCount: statement.int(4),
            lastVisit: Date(timeIntervalSince1970: statement.double(5))
        )
    }

    static func bindings(
        id: UUID, url: URL, host: String, title: String, visitCount: Int, lastVisit: Date
    ) -> [SQLiteValue] {
        [
            .text(id.uuidString), .text(url.absoluteString), .text(host),
            .text(title), .int(Int64(visitCount)), .double(lastVisit.timeIntervalSince1970)
        ]
    }

    /// Strips the query string and fragment — noise in a suggestion list and
    /// a privacy leak (AGENTS.md §5) — while keeping the path.
    static func storableURL(_ url: URL) -> URL? {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        components.user = nil
        components.password = nil
        components.query = nil
        components.fragment = nil
        return components.url
    }
}
