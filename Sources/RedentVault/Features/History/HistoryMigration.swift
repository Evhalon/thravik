import Foundation

enum HistoryMigration {
    static func run(on connection: SQLiteConnection) throws {
        let version = try currentVersion(on: connection)
        guard version < HistorySchema.version else { return }
        try connection.execute("BEGIN TRANSACTION")
        do {
            try migrateAggregate(on: connection)
            try connection.execute(HistorySchema.createContextualTable)
            try connection.execute("PRAGMA user_version = \(HistorySchema.version)")
            try connection.execute("COMMIT")
        } catch {
            try? connection.execute("ROLLBACK")
            throw error
        }
    }

    private static func currentVersion(on connection: SQLiteConnection) throws -> Int {
        var version = 0
        try connection.query("PRAGMA user_version") { statement in version = statement.int(0) }
        return version
    }

    private static func migrateAggregate(on connection: SQLiteConnection) throws {
        guard try !hasTable("visits", on: connection) else {
            guard try !hasColumn("visits", named: "unknown_count", on: connection) else { return }
            try connection.execute("ALTER TABLE visits ADD COLUMN unknown_count INTEGER NOT NULL DEFAULT 0")
            try connection.execute("UPDATE visits SET unknown_count = visit_count")
            return
        }
        try connection.execute(HistorySchema.createAggregateTable)
    }

    private static func hasTable(_ name: String, on connection: SQLiteConnection) throws -> Bool {
        var found = false
        try connection.query(
            "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = ?",
            bindings: [.text(name)]
        ) { _ in found = true }
        return found
    }

    private static func hasColumn(
        _ table: String, named name: String, on connection: SQLiteConnection
    ) throws -> Bool {
        var found = false
        try connection.query("PRAGMA table_info(\(table))") { statement in
            if statement.text(1) == name { found = true }
        }
        return found
    }
}
