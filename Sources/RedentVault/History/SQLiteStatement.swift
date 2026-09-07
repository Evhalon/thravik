import SQLite3

// SQLITE_TRANSIENT tells SQLite to copy bound text/blob data immediately,
// since the Swift string backing it isn't guaranteed to outlive the call.
private let sqliteTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

/// A prepared statement, positioned to read one result row at a time.
///
/// Callers must copy any text/blob column immediately: `sqlite3_column_*`
/// pointers are invalidated by the next `step()` or by `finalize`.
final class SQLiteStatement {
    fileprivate let handle: OpaquePointer

    init(handle: OpaquePointer) {
        self.handle = handle
    }

    deinit {
        sqlite3_finalize(handle)
    }

    func bind(_ values: [SQLiteValue]) {
        for (offset, value) in values.enumerated() {
            let index = Int32(offset + 1)
            switch value {
            case .text(let string):
                sqlite3_bind_text(handle, index, string, -1, sqliteTransient)
            case .int(let number):
                sqlite3_bind_int64(handle, index, number)
            case .double(let number):
                sqlite3_bind_double(handle, index, number)
            case .null:
                sqlite3_bind_null(handle, index)
            }
        }
    }

    @discardableResult
    func step() -> Int32 {
        sqlite3_step(handle)
    }

    func reset() {
        sqlite3_reset(handle)
        sqlite3_clear_bindings(handle)
    }

    func text(_ column: Int32) -> String {
        guard let cString = sqlite3_column_text(handle, column) else { return "" }
        return String(cString: cString)
    }

    func int(_ column: Int32) -> Int {
        Int(sqlite3_column_int64(handle, column))
    }

    func double(_ column: Int32) -> Double {
        sqlite3_column_double(handle, column)
    }
}
