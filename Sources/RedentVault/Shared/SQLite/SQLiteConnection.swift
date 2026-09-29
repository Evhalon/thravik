import Foundation
import SQLite3

/// A thin wrapper around the SQLite C API so no call site outside this file
/// (and `SQLiteStatement`) touches a raw `OpaquePointer`.
final class SQLiteConnection {
    private var handle: OpaquePointer?

    init(path: String) throws {
        var db: OpaquePointer?
        let status = sqlite3_open_v2(path, &db, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, nil)
        guard status == SQLITE_OK, let db else {
            sqlite3_close(db)
            throw SQLiteError.openFailed(status)
        }
        handle = db
    }

    deinit {
        sqlite3_close(handle)
    }

    /// Runs statements with no bindable parameters and no result rows —
    /// pragmas, schema creation, transaction control.
    func execute(_ sql: String) throws {
        guard let handle else { throw SQLiteError.closed }
        guard sqlite3_exec(handle, sql, nil, nil, nil) == SQLITE_OK else {
            throw SQLiteError.stepFailed(String(cString: sqlite3_errmsg(handle)))
        }
    }

    func prepare(_ sql: String) throws -> SQLiteStatement {
        guard let handle else { throw SQLiteError.closed }
        var statementHandle: OpaquePointer?
        guard sqlite3_prepare_v2(handle, sql, -1, &statementHandle, nil) == SQLITE_OK,
              let statementHandle
        else {
            throw SQLiteError.prepareFailed(String(cString: sqlite3_errmsg(handle)))
        }
        return SQLiteStatement(handle: statementHandle)
    }

    /// Prepares, binds, and steps a single write (insert/update/delete) once.
    func run(_ sql: String, bindings: [SQLiteValue] = []) throws {
        let statement = try prepare(sql)
        statement.bind(bindings)
        let status = statement.step()
        guard status == SQLITE_DONE || status == SQLITE_ROW else {
            throw SQLiteError.stepFailed("step failed: \(status)")
        }
    }

    func changes() -> Int {
        guard let handle else { return 0 }
        return Int(sqlite3_changes(handle))
    }

    /// Prepares, binds, and steps through every result row.
    func query(_ sql: String, bindings: [SQLiteValue] = [], row: (SQLiteStatement) throws -> Void) throws {
        let statement = try prepare(sql)
        statement.bind(bindings)
        while statement.step() == SQLITE_ROW {
            try row(statement)
        }
    }
}
