import Foundation

public enum RecentlyClosedKind: Sendable, Hashable {
    case tab
    case group(tabCount: Int)
}
