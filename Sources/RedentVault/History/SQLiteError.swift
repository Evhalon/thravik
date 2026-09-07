import Foundation

/// Failures from the internal SQLite wrapper. Never surfaced through
/// `HistoryStoring` — callers degrade to empty results instead, since
/// history is a cache, not a source of truth.
enum SQLiteError: Error, Sendable {
    case openFailed(Int32)
    case closed
    case prepareFailed(String)
    case stepFailed(String)
}
