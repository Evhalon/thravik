import Foundation

extension HistoryDatabase {
    func clear(domain rawDomain: String, containerID: UUID?) {
        guard let connection, let domain = HistorySQL.domain(rawDomain) else { return }
        let host = domain
        let suffix = "%.\(HistorySQL.escapedLike(domain))"
        do {
            let urls = try affectedURLs(host: host, suffix: suffix, on: connection)
            try connection.execute("BEGIN TRANSACTION")
            try deleteContextual(host: host, suffix: suffix, containerID: containerID, on: connection)
            if containerID == nil {
                try clearUnknownCount(urls, on: connection)
            }
            for url in urls { try refreshAggregate(url, on: connection) }
            try connection.execute("COMMIT")
        } catch {
            try? connection.execute("ROLLBACK")
        }
    }

    private func affectedURLs(
        host: String, suffix: String, on connection: SQLiteConnection
    ) throws -> [String] {
        var urls: [String] = []
        try connection.query(
            "SELECT url FROM visits WHERE host = ? OR host LIKE ? ESCAPE '\\'",
            bindings: [.text(host), .text(suffix)]
        ) { statement in urls.append(statement.text(0)) }
        return urls
    }

    private func deleteContextual(
        host: String, suffix: String, containerID: UUID?, on connection: SQLiteConnection
    ) throws {
        var sql = "DELETE FROM contextual_visits WHERE (host = ? OR host LIKE ? ESCAPE '\\')"
        var bindings: [SQLiteValue] = [.text(host), .text(suffix)]
        if let containerID {
            sql += " AND container_id = ?"
            bindings.append(.text(containerID.uuidString))
        }
        try connection.run(sql, bindings: bindings)
    }

    private func clearUnknownCount(_ urls: [String], on connection: SQLiteConnection) throws {
        for url in urls {
            try connection.run("UPDATE visits SET unknown_count = 0 WHERE url = ?", bindings: [.text(url)])
        }
    }

    private func refreshAggregate(_ url: String, on connection: SQLiteConnection) throws {
        var count = 0
        var latest: Double?
        try connection.query(
            "SELECT COUNT(*), MAX(visited_at) FROM contextual_visits WHERE url = ?",
            bindings: [.text(url)]
        ) { statement in
            count = statement.int(0)
            latest = statement.double(1)
        }
        var unknown = 0
        var oldDate = 0.0
        try connection.query(
            "SELECT unknown_count, last_visit FROM visits WHERE url = ?", bindings: [.text(url)]
        ) { statement in
            unknown = statement.int(0)
            oldDate = statement.double(1)
        }
        guard unknown + count > 0 else {
            try connection.run("DELETE FROM visits WHERE url = ?", bindings: [.text(url)])
            return
        }
        let date = unknown > 0 ? max(oldDate, latest ?? 0) : (latest ?? 0)
        try connection.run(
            "UPDATE visits SET visit_count = ?, last_visit = ? WHERE url = ?",
            bindings: [.int(Int64(unknown + count)), .double(date), .text(url)]
        )
    }
}
