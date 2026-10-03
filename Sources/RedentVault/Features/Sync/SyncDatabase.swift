import Foundation
import SQLite3
import RedentKit

/// Actor-owned: transactions never suspend while the SQLite connection is locked.
final class SyncDatabase {
    let connection: SQLiteConnection

    init(fileURL: URL) throws {
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(),
                                               withIntermediateDirectories: true)
        connection = try SQLiteConnection(path: fileURL.path)
        try connection.execute("PRAGMA journal_mode=WAL; PRAGMA synchronous=FULL; PRAGMA busy_timeout=5000;")
        try connection.execute("""
            CREATE TABLE IF NOT EXISTS sync_outbox (
                sequence INTEGER PRIMARY KEY AUTOINCREMENT, owner TEXT NOT NULL,
                mutation_id TEXT NOT NULL UNIQUE, encoded TEXT NOT NULL);
            CREATE INDEX IF NOT EXISTS sync_outbox_owner ON sync_outbox(owner, sequence);
            CREATE TABLE IF NOT EXISTS sync_records (
                owner TEXT NOT NULL, collection TEXT NOT NULL, record_id TEXT NOT NULL,
                revision INTEGER NOT NULL, encoded TEXT NOT NULL,
                PRIMARY KEY(owner, collection, record_id));
            CREATE TABLE IF NOT EXISTS sync_cursors (owner TEXT PRIMARY KEY, cursor INTEGER NOT NULL);
            """)
    }

    func transaction(_ body: () throws -> Void) throws {
        try connection.execute("BEGIN IMMEDIATE")
        do {
            try body()
            try connection.execute("COMMIT")
        } catch {
            try? connection.execute("ROLLBACK")
            throw error
        }
    }

    func read<T>(_ sql: String, bindings: [SQLiteValue] = [], decode: (SQLiteStatement) throws -> T) throws -> [T] {
        let statement = try connection.prepare(sql)
        statement.bind(bindings)
        var rows: [T] = []
        var status = statement.step()
        while status == SQLITE_ROW {
            rows.append(try decode(statement))
            status = statement.step()
        }
        guard status == SQLITE_DONE else { throw SQLiteError.stepFailed("sync read failed") }
        return rows
    }

    func persist(_ record: SyncRemoteRecord) throws {
        let identity = record.mutation.identity
        let encoded = try JSONEncoder().encode(record).base64EncodedString()
        try connection.run("""
            INSERT INTO sync_records(owner, collection, record_id, revision, encoded) VALUES(?,?,?,?,?)
            ON CONFLICT(owner, collection, record_id) DO UPDATE SET
            revision=excluded.revision, encoded=excluded.encoded WHERE excluded.revision > sync_records.revision
            """, bindings: [.text(identity.accountID.uuidString), .text(identity.collection),
                            .text(identity.recordID.uuidString), .int(record.revision), .text(encoded)])
    }

    func decode<T: Decodable>(_ type: T.Type, row: SQLiteStatement) throws -> T {
        guard let data = Data(base64Encoded: row.text(0)),
              let value = try? JSONDecoder().decode(type, from: data) else { throw VaultError.invalidData }
        return value
    }
}
