import Foundation

/// A value bindable to a `?` placeholder in a prepared statement.
enum SQLiteValue {
    case text(String)
    case int(Int64)
    case double(Double)
    case null

    static func uuid(_ value: UUID?) -> SQLiteValue {
        guard let value else { return .null }
        return .text(value.uuidString)
    }
}
