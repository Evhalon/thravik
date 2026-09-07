import Foundation

/// Which tabs a window shows side by side, and which pane the chrome acts on.
///
/// Capped at two panes on purpose: a second live renderer already costs real
/// memory, and this browser exists because that cost is not free. One tab never
/// appears in both panes — WebKit cannot mount one view twice.
public struct SplitLayout: Codable, Sendable, Hashable {
    public enum Orientation: String, Codable, Sendable, Hashable {
        case horizontal
        case vertical
    }

    public enum Pane: String, Codable, Sendable, Hashable {
        case primary
        case secondary
    }

    public static let minimumRatio = 0.25
    public static let maximumRatio = 0.75

    public private(set) var secondaryTabID: UUID?
    public private(set) var activePane: Pane = .primary
    public var orientation: Orientation = .horizontal
    public private(set) var ratio: Double = 0.5

    public init() {}

    public var isSplit: Bool { secondaryTabID != nil }

    public mutating func split(with tabID: UUID, primary: UUID?) {
        guard tabID != primary else { return }
        secondaryTabID = tabID
        activePane = .secondary
    }

    public mutating func closeSecondary() {
        secondaryTabID = nil
        activePane = .primary
    }

    public mutating func focus(_ pane: Pane) {
        guard pane == .primary || isSplit else { return }
        activePane = pane
    }

    public mutating func togglePane() {
        focus(activePane == .primary ? .secondary : .primary)
    }

    /// Clamped so a drag can never collapse a pane to nothing.
    public mutating func setRatio(_ value: Double) {
        ratio = min(max(value, Self.minimumRatio), Self.maximumRatio)
    }

    /// A pane whose tab was closed or moved away stops being a pane.
    public mutating func validate(against tabIDs: Set<UUID>) {
        guard let id = secondaryTabID, !tabIDs.contains(id) else { return }
        closeSecondary()
    }

    /// The tab the chrome acts on: keyboard, autofill, one-time codes.
    public func activeTabID(primary: UUID?) -> UUID? {
        guard activePane == .secondary, let secondaryTabID else { return primary }
        return secondaryTabID
    }

    /// Everything on screen. Hibernation must spare all of it, not just the
    /// window's selection.
    public func visibleTabIDs(primary: UUID?) -> Set<UUID> {
        Set([primary, secondaryTabID].compactMap { $0 })
    }
}
