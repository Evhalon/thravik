import Foundation
import RedentKit

extension HistoryDatabase {
    func search(_ text: String, limit: Int) -> [HistoryEntry] {
        query(HistoryQuery(text: text, limit: limit))
    }

    func recent(limit: Int) -> [HistoryEntry] {
        query(HistoryQuery(limit: limit, sort: .recent))
    }

    func mostVisited(limit: Int) -> [HistoryEntry] {
        query(HistoryQuery(limit: limit, sort: .mostVisited))
    }

    func query(_ request: HistoryQuery) -> [HistoryEntry] {
        guard let connection, request.limit > 0 else { return [] }
        let scoped = request.scope.spaceID != nil || request.scope.containerID != nil
        let result = scoped ? scopedRows(request, on: connection) : aggregateRows(request, on: connection)
        return ranked(result, for: request)
    }

    private func aggregateRows(
        _ request: HistoryQuery, on connection: SQLiteConnection
    ) -> [HistoryEntry] {
        var bindings: [SQLiteValue] = []
        let filters = filters(for: request, columnPrefix: "") { value in bindings.append(.text(value)) }
        let sql = "SELECT \(HistorySchema.columns) FROM visits WHERE \(filters)"
        return rows(from: connection, sql: sql, bindings: bindings)
    }

    private func scopedRows(
        _ request: HistoryQuery, on connection: SQLiteConnection
    ) -> [HistoryEntry] {
        var bindings: [SQLiteValue] = []
        let filters = filters(for: request, columnPrefix: "v.") { value in bindings.append(.text(value)) }
        var context = ""
        if let id = request.scope.spaceID {
            context += " AND cv.space_id = ?"
            bindings.append(.text(id.uuidString))
        }
        if let id = request.scope.containerID {
            context += " AND cv.container_id = ?"
            bindings.append(.text(id.uuidString))
        }
        let sql = """
        SELECT v.id, v.url, v.host, v.title, COUNT(cv.navigation_id),
          COALESCE(MAX(cv.visited_at), v.last_visit)
        FROM visits v JOIN contextual_visits cv ON cv.url = v.url
        WHERE \(filters)\(context) GROUP BY v.id
        """
        return rows(from: connection, sql: sql, bindings: bindings)
    }

    private func filters(
        for request: HistoryQuery, columnPrefix: String, bind: (String) -> Void
    ) -> String {
        let prefix = columnPrefix
        var clauses = ["1 = 1"]
        if !request.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let pattern = "%\(HistorySQL.escapedLike(request.text))%"
            clauses.append("(\(prefix)host LIKE ? ESCAPE '\\' OR \(prefix)url LIKE ? ESCAPE '\\' OR \(prefix)title LIKE ? ESCAPE '\\')")
            bind(pattern); bind(pattern); bind(pattern)
        }
        if let domain = request.scope.domain.flatMap(HistorySQL.domain) {
            clauses.append("(\(prefix)host = ? OR \(prefix)host LIKE ? ESCAPE '\\')")
            bind(domain); bind("%.\(HistorySQL.escapedLike(domain))")
        }
        return clauses.joined(separator: " AND ")
    }

    private func ranked(_ entries: [HistoryEntry], for request: HistoryQuery) -> [HistoryEntry] {
        switch request.sort {
        case .recent:
            return Array(entries.sorted { $0.lastVisit > $1.lastVisit }.prefix(request.limit))
        case .mostVisited:
            return HistoryRanking.bestPerHost(entries, at: .now, limit: request.limit)
        case .relevance where request.text.isEmpty:
            return Array(entries.sorted { $0.lastVisit > $1.lastVisit }.prefix(request.limit))
        case .relevance:
            return HistoryRanking.rank(entries, matching: request.text, at: .now, limit: request.limit)
        }
    }

    private func rows(
        from connection: SQLiteConnection, sql: String, bindings: [SQLiteValue]
    ) -> [HistoryEntry] {
        var entries: [HistoryEntry] = []
        try? connection.query(sql, bindings: bindings) { statement in
            if let entry = HistoryRow.entry(from: statement) { entries.append(entry) }
        }
        return entries
    }
}
