import Foundation

/// One completed navigation, retained separately from page aggregates.
public struct HistoryVisit: Hashable, Sendable, Codable {
    public var context: HistoryVisitContext
    public var url: URL
    public var title: String
    public var date: Date

    public var navigationID: UUID {
        get { context.navigationID }
        set { context.navigationID = newValue }
    }
    public var tabID: UUID? {
        get { context.tabID }
        set { context.tabID = newValue }
    }
    public var spaceID: UUID? {
        get { context.spaceID }
        set { context.spaceID = newValue }
    }
    public var containerID: UUID? {
        get { context.containerID }
        set { context.containerID = newValue }
    }

    public init(
        url: URL,
        title: String = "",
        date: Date = .now,
        context: HistoryVisitContext = HistoryVisitContext()
    ) {
        self.context = context
        self.url = url
        self.title = title
        self.date = date
    }
}
