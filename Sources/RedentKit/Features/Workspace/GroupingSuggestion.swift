import Foundation

public struct GroupingSuggestion: Identifiable, Hashable, Sendable {
    public let id: String
    public let origin: Origin
    public let tabIDs: [UUID]
    public let name: String
    public let reason: String

    public init(origin: Origin, tabIDs: [UUID]) {
        self.origin = origin
        self.tabIDs = tabIDs
        self.id = origin.description
        self.name = origin.displayHost
        self.reason = "\(tabIDs.count) tabs from \(origin.displayHost)"
    }
}
