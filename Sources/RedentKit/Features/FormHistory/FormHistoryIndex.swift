import Foundation

/// One remembered value, and how much it has been used.
public struct FormHistoryRow: Codable, Sendable, Equatable {
    public let key: FormFieldKey
    public let value: String
    public var useCount: Int
    public var lastUsed: Date

    public init(key: FormFieldKey, value: String, useCount: Int = 1, lastUsed: Date) {
        self.key = key
        self.value = value
        self.useCount = useCount
        self.lastUsed = lastUsed
    }
}

/// The whole of form history as a value: recording, ranking and pruning with
/// no I/O, so a store only has to read and write it.
public struct FormHistoryIndex: Codable, Sendable, Equatable {
    public private(set) var rows: [FormHistoryRow]

    /// Enough for years of ordinary use, small enough to read whole.
    public static let capacity = 2_000

    public init(rows: [FormHistoryRow] = []) { self.rows = rows }

    /// Values differing only in case are one entry; the latest spelling wins.
    public mutating func record(_ entries: [FormEntry], at date: Date) {
        for entry in entries {
            if let index = rows.firstIndex(where: { $0.key == entry.key && Self.same($0.value, entry.value) }) {
                let used = rows[index].useCount + 1
                rows[index] = FormHistoryRow(key: entry.key, value: entry.value, useCount: used, lastUsed: date)
            } else {
                rows.append(FormHistoryRow(key: entry.key, value: entry.value, lastUsed: date))
            }
        }
        prune()
    }

    /// Case-insensitive prefix matches, most used first and newest among
    /// equals. What is already typed in full is not offered back.
    public func suggestions(for key: FormFieldKey, matching prefix: String, limit: Int) -> [String] {
        let typed = prefix.trimmingCharacters(in: .whitespaces)
        return rows
            .filter { $0.key == key && Self.starts($0.value, with: typed) && !Self.same($0.value, typed) }
            .sorted { lhs, rhs in
                lhs.useCount == rhs.useCount ? lhs.lastUsed > rhs.lastUsed : lhs.useCount > rhs.useCount
            }
            .prefix(max(limit, 0))
            .map(\.value)
    }

    public mutating func remove(_ value: String, for key: FormFieldKey) {
        rows.removeAll { $0.key == key && Self.same($0.value, value) }
    }

    private mutating func prune() {
        guard rows.count > Self.capacity else { return }
        rows.sort { $0.lastUsed > $1.lastUsed }
        rows.removeLast(rows.count - Self.capacity)
    }

    private static func same(_ lhs: String, _ rhs: String) -> Bool {
        lhs.compare(rhs, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
    }

    private static func starts(_ value: String, with prefix: String) -> Bool {
        prefix.isEmpty || value.range(of: prefix, options: [.anchored, .caseInsensitive, .diacriticInsensitive]) != nil
    }
}
