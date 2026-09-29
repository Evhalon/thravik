import Foundation

/// How the tab arrived at an entry. Recorded from what the engine reports, not
/// inferred, so a reload never reads as a fresh visit.
public enum NavigationTransition: String, Codable, Sendable, Hashable {
    case opened
    case link
    case formSubmitted
    case reload
    case traversal
    case redirect
    case sameDocument

    public var label: String {
        switch self {
        case .opened: "Opened"
        case .link: "Followed link"
        case .formSubmitted: "Submitted form"
        case .reload: "Reloaded"
        case .traversal: "Went back or forward"
        case .redirect: "Redirected"
        case .sameDocument: "Moved within page"
        }
    }
}

/// One step in a tab's own path, distinct from the global history aggregate.
public struct NavigationEntry: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public let sequence: Int
    public let url: URL
    public var title: String
    public let transition: NavigationTransition
    public let visitedAt: Date
    /// Whether the engine still holds live state for this entry. Restored
    /// entries lose it, and the panel then offers a plain reload instead of
    /// pretending the old page state can come back.
    public var hasLiveState: Bool

    public init(
        id: UUID = UUID(), sequence: Int, url: URL, title: String = "",
        transition: NavigationTransition, visitedAt: Date = .now, hasLiveState: Bool = false
    ) {
        self.id = id
        self.sequence = sequence
        self.url = url
        self.title = title
        self.transition = transition
        self.visitedAt = visitedAt
        self.hasLiveState = hasLiveState
    }

    public var displayTitle: String {
        if !title.isEmpty { return title }
        return Origin(url: url)?.displayHost ?? url.absoluteString
    }

    /// What the user can actually get back, said plainly.
    public var restoreLabel: String { hasLiveState ? "Go" : "Reload URL" }
}
