import Foundation

/// A tab's navigation provenance, bounded and in order.
///
/// The engine reports each step with the transition it actually observed; the
/// only thing collapsed here is the duplicate a same-URL link navigation
/// produces, because that is one arrival reported twice, not two visits.
public struct TabTimeline: Codable, Sendable, Hashable {
    public static let limit = 100

    public private(set) var entries: [NavigationEntry] = []

    public init(entries: [NavigationEntry] = []) { self.entries = entries }

    public var current: NavigationEntry? { entries.last }

    @discardableResult
    public mutating func record(
        url: URL, title: String = "", transition: NavigationTransition, at date: Date = .now
    ) -> NavigationEntry? {
        if let last = entries.last, last.url == url, isDuplicate(transition) { return nil }
        let entry = NavigationEntry(
            sequence: (entries.last?.sequence ?? -1) + 1,
            url: url, title: title, transition: transition, visitedAt: date, hasLiveState: true
        )
        entries.append(entry)
        if entries.count > Self.limit { entries.removeFirst(entries.count - Self.limit) }
        return entry
    }

    public mutating func updateTitle(_ title: String, for id: UUID) {
        guard !title.isEmpty, let index = entries.firstIndex(where: { $0.id == id }) else { return }
        entries[index].title = title
    }

    /// Live state belongs to a live web view. Once the view is gone the entries
    /// can only be reloaded by URL, and they say so.
    public mutating func dropLiveState() {
        for index in entries.indices { entries[index].hasLiveState = false }
    }

    /// Forgetting a site reaches the per-tab path too, or the timeline would
    /// keep handing back the URLs that were just erased.
    public mutating func forget(domain: String) {
        entries.removeAll { Origin(url: $0.url)?.registrableDomain == domain }
    }

    /// Only what would survive a relaunch — live state never does.
    public func persistable(limit: Int = 25) -> TabTimeline {
        var trimmed = Array(entries.suffix(limit))
        for index in trimmed.indices { trimmed[index].hasLiveState = false }
        return TabTimeline(entries: trimmed)
    }

    private func isDuplicate(_ transition: NavigationTransition) -> Bool {
        transition == .link || transition == .sameDocument
    }
}
