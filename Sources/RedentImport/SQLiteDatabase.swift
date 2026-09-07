import Foundation
import RedentKit
import SQLite3

/// A thin, read-only wrapper around the SQLite C API so no call site in this
/// target touches a raw `OpaquePointer` or `sqlite3_stmt`.
final class SQLiteDatabase {
    private var handle: OpaquePointer?

    /// Opens the database file at `url` read-only.
    init(readOnlyAt url: URL) throws {
        var db: OpaquePointer?
        let status = sqlite3_open_v2(url.path, &db, SQLITE_OPEN_READONLY, nil)
        guard status == SQLITE_OK, let db else {
            sqlite3_close(db)
            throw ImportError.databaseUnreadable(url.lastPathComponent)
        }
        handle = db
    }

    deinit {
        sqlite3_close(handle)
    }

    /// Runs `query`, invoking `row` for each result row with a `Statement`
    /// positioned to read that row's columns.
    func query(_ sql: String, row: (Statement) throws -> Void) throws {
        guard let handle else { throw ImportError.databaseUnreadable("closed") }
        var statementHandle: OpaquePointer?
        guard sqlite3_prepare_v2(handle, sql, -1, &statementHandle, nil) == SQLITE_OK,
              let statementHandle
        else {
            throw ImportError.databaseUnreadable("prepare failed")
        }
        defer { sqlite3_finalize(statementHandle) }

        let statement = Statement(handle: statementHandle)
        while sqlite3_step(statementHandle) == SQLITE_ROW {
            try row(statement)
        }
    }

    /// Read access to one result row. Only valid for the duration of the
    /// `query(_:row:)` callback that receives it — `sqlite3_step` invalidates
    /// any text pointers handed out by the previous row.
    struct Statement {
        fileprivate let handle: OpaquePointer

        func text(_ column: Int32) -> String? {
            guard let cString = sqlite3_column_text(handle, column) else { return nil }
            // Copy immediately: the pointer is only valid until the next
            // sqlite3_step or sqlite3_finalize call.
            return String(cString: cString)
        }

        func blob(_ column: Int32) -> Data? {
            guard let pointer = sqlite3_column_blob(handle, column) else { return nil }
            let count = Int(sqlite3_column_bytes(handle, column))
            return Data(bytes: pointer, count: count)
        }

        func int64(_ column: Int32) -> Int64 {
            sqlite3_column_int64(handle, column)
        }

        func int(_ column: Int32) -> Int {
            Int(sqlite3_column_int64(handle, column))
        }
    }
}
