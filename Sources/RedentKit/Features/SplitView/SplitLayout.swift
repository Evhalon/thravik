import Foundation

/// A set of tabs a window shows side by side, the way Dia does it: the split
/// is one entry in the tab list, on screen whenever one of its tabs is the
/// selection, and set aside — not undone — when the user selects another tab.
///
/// Capped at `maximumPanes`: every pane is a live renderer, and this browser
/// exists because that cost is not free. One tab never appears in two panes —
/// WebKit cannot mount one view twice.
public struct SplitLayout: Sendable, Hashable {
    public enum Orientation: String, Codable, Sendable, Hashable {
        case horizontal
        case vertical
    }

    public static let maximumPanes = 4
    /// The smallest share of the window a drag can leave a pane with.
    public static let minimumFraction = 0.12

    /// The panes' tabs, in pane order. Empty, or at least two.
    public internal(set) var tabIDs: [UUID] = []
    public var orientation: Orientation = .horizontal
    /// Each pane's share of the window, in pane order. Always sums to one.
    public internal(set) var fractions: [Double] = []

    public init() {}

    public var isSplit: Bool { tabIDs.count > 1 }
    public var paneCount: Int { tabIDs.count }
    public var canAddPane: Bool { paneCount < Self.maximumPanes }

    /// Whether the split is what the window shows for this selection.
    public func isShowing(primary: UUID?) -> Bool {
        guard isSplit, let primary else { return false }
        return tabIDs.contains(primary)
    }

    /// Puts `tabID` beside the selection. Splitting from a tab outside the
    /// current split starts a new one — a window holds a single split.
    public mutating func split(with tabID: UUID, primary: UUID?) {
        guard let primary, tabID != primary else { return }
        if !tabIDs.contains(primary) { tabIDs = [primary] }
        guard !tabIDs.contains(tabID), canAddPane else { return }
        tabIDs.append(tabID)
        equalize()
    }

    /// Ends the split; every tab in it stays open.
    public mutating func closeSplit() {
        tabIDs = []
        fractions = []
    }

    /// Takes one tab out. A split left with one tab is no split at all.
    public mutating func remove(_ tabID: UUID) {
        guard let index = tabIDs.firstIndex(of: tabID) else { return }
        tabIDs.remove(at: index)
        if tabIDs.count < 2 { closeSplit() } else { equalize() }
    }

    /// Moves the seam after pane `divider` by `delta`, a share of the window.
    /// Only the two panes either side of it change size, and neither can be
    /// dragged below `minimumFraction`.
    public mutating func resize(divider: Int, from start: [Double], by delta: Double) {
        guard start.count == paneCount, fractions.count == paneCount,
              (0..<paneCount - 1).contains(divider) else { return }
        let pair = start[divider] + start[divider + 1]
        let leading = min(max(start[divider] + delta, Self.minimumFraction), pair - Self.minimumFraction)
        fractions = start
        fractions[divider] = leading
        fractions[divider + 1] = pair - leading
    }

    /// A pane whose tab was closed or moved away stops being a pane.
    public mutating func validate(against existing: Set<UUID>) {
        for id in tabIDs where !existing.contains(id) { remove(id) }
    }

    /// The pane after the one showing `primary`, wrapping round.
    public func tabID(after primary: UUID?) -> UUID? {
        guard isShowing(primary: primary), let primary, let index = tabIDs.firstIndex(of: primary) else { return nil }
        return tabIDs[(index + 1) % paneCount]
    }

    /// Everything on screen. Hibernation must spare all of it, not just the
    /// window's selection.
    public func visibleTabIDs(primary: UUID?) -> Set<UUID> {
        isShowing(primary: primary) ? Set(tabIDs) : Set([primary].compactMap { $0 })
    }

    private mutating func equalize() {
        fractions = Array(repeating: 1 / Double(paneCount), count: paneCount)
    }
}
