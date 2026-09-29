import Foundation
import RedentKit

extension HistoryDatabase {
    func record(_ visit: HistoryVisit) {
        guard let connection,
              let origin = Origin(url: visit.url),
              let url = HistoryRow.storableURL(visit.url)
        else { return }
        let title = visit.title.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            try connection.run(
                """
                INSERT OR IGNORE INTO contextual_visits
                (navigation_id, url, host, title, tab_id, space_id, container_id, visited_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                """,
                bindings: [SQLiteValue](arrayLiteral:
                    .text(visit.navigationID.uuidString), .text(url.absoluteString),
                    .text(origin.host), .text(title), .uuid(visit.tabID),
                    .uuid(visit.spaceID), .uuid(visit.containerID),
                    .double(visit.date.timeIntervalSince1970)
                )
            )
            guard connection.changes() == 1 else { return }
            try upsert(url: url, host: origin.host, title: title, date: visit.date, on: connection)
        } catch {}
    }

    private func upsert(
        url: URL, host: String, title: String, date: Date, on connection: SQLiteConnection
    ) throws {
        try connection.run(
            """
            INSERT INTO visits (id, url, host, title, visit_count, last_visit, unknown_count)
            VALUES (?, ?, ?, ?, 1, ?, 0)
            ON CONFLICT(url) DO UPDATE SET
              visit_count = visit_count + 1,
              last_visit = MAX(last_visit, excluded.last_visit),
              title = CASE WHEN excluded.title <> '' THEN excluded.title ELSE visits.title END
            """,
            bindings: [
                .text(UUID().uuidString), .text(url.absoluteString), .text(host), .text(title),
                .double(date.timeIntervalSince1970)
            ]
        )
    }
}
