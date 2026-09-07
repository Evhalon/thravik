import Foundation

/// Identity captured when a navigation event is emitted by the browser.
public struct HistoryVisitContext: Hashable, Sendable, Codable {
    public var navigationID: UUID
    public var tabID: UUID?
    public var spaceID: UUID?
    public var containerID: UUID?

    public init(
        navigationID: UUID = UUID(),
        tabID: UUID? = nil,
        spaceID: UUID? = nil,
        containerID: UUID? = nil
    ) {
        self.navigationID = navigationID
        self.tabID = tabID
        self.spaceID = spaceID
        self.containerID = containerID
    }
}
