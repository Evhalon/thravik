import Foundation

/// One page the user has been to.
public struct HistoryEntry: Identifiable, Hashable, Sendable, Codable {
    public let id: UUID
    public let url: URL
    public var title: String
    public var visitCount: Int
    public var lastVisit: Date

    public init(
        id: UUID = UUID(),
        url: URL,
        title: String = "",
        visitCount: Int = 1,
        lastVisit: Date = .now
    ) {
        self.id = id
        self.url = url
        self.title = title
        self.visitCount = max(0, visitCount)
        self.lastVisit = lastVisit
    }

    public var origin: Origin? { Origin(url: url) }

    public var displayTitle: String {
        title.isEmpty ? (origin?.displayHost ?? url.absoluteString) : title
    }

    /// Frecency: how often, weighted by how recently.
    ///
    /// A page visited twice this morning should outrank one visited thirty
    /// times last year, so recency decays on a half-life rather than being a
    /// tiebreaker.
    public func score(at now: Date = .now) -> Double {
        let days = max(0, now.timeIntervalSince(lastVisit) / 86_400)
        let recency = pow(0.5, days / 7)
        return (1 + log2(Double(visitCount) + 1)) * recency
    }
}
