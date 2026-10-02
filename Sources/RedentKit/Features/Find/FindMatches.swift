import Foundation

/// The result of a find-in-page pass: how many matches the page holds, and
/// which one is highlighted. The find bar reads it as "3/12".
public struct FindMatches: Sendable, Equatable {
    /// Every match on the page when `isCountExact` is true.
    public let total: Int
    /// The highlighted match, counting from one. Zero when nothing matched.
    public let current: Int
    /// Native document search can confirm a match without exposing its count.
    public let isCountExact: Bool

    public static let empty = FindMatches(total: 0, current: 0)
    public static let foundWithoutCount = FindMatches(total: 1, current: 1, isCountExact: false)

    public var isEmpty: Bool { total == 0 }

    public init(total: Int, current: Int, isCountExact: Bool = true) {
        let matches = max(0, total)
        self.total = matches
        self.current = matches == 0 ? 0 : min(max(current, 1), matches)
        self.isCountExact = isCountExact
    }
}
