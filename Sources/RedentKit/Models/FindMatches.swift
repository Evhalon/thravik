import Foundation

/// The result of a find-in-page pass: how many matches the page holds, and
/// which one is highlighted. The find bar reads it as "3/12".
public struct FindMatches: Sendable, Equatable {
    /// Every match on the page. The engine caps this on pathological pages;
    /// past a couple of thousand hits a counter tells the reader nothing.
    public let total: Int
    /// The highlighted match, counting from one. Zero when nothing matched.
    public let current: Int

    public static let empty = FindMatches(total: 0, current: 0)

    public var isEmpty: Bool { total == 0 }

    public init(total: Int, current: Int) {
        let matches = max(0, total)
        self.total = matches
        self.current = matches == 0 ? 0 : min(max(current, 1), matches)
    }
}
