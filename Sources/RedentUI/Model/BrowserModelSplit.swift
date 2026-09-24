import Foundation
import RedentKit

/// Split View from the window's side. The active pane is always the window's
/// selection, so the toolbar, autofill and one-time codes follow the page the
/// user last clicked without a second notion of "current tab".
extension BrowserModel {
    public var selectedTab: (any BrowserTab)? { tabs.selectedTab }

    /// Whether the window is showing its split right now.
    public var isShowingSplit: Bool { split.isShowing(primary: tabs.selectedID) }

    /// The split's tabs in pane order, whether or not it is on screen.
    public var splitTabs: [any BrowserTab] {
        split.tabIDs.compactMap { id in tabs.tabs.first { $0.id == id } }
    }

    /// Adds the next tab of the Space that is not already in the split beside
    /// the selection. Nothing to split with is not an error — it just does not.
    public func splitWithNextTab() {
        let taken = isShowingSplit ? Set(split.tabIDs) : Set([tabs.selectedID].compactMap { $0 })
        guard let neighbour = tabs.visibleTabs.first(where: { !taken.contains($0.id) }) else { return }
        splitWith(neighbour.id)
    }

    /// Opens `tabID` beside the selection, and keeps the selection where it was
    /// — the user asked to see that tab, not to leave this one.
    public func splitWith(_ tabID: UUID) {
        split.split(with: tabID, primary: tabs.selectedID)
    }

    /// Whether a tab row can offer "Open in Split View".
    public func canSplit(with tabID: UUID) -> Bool {
        guard let selected = tabs.selectedID, selected != tabID else { return false }
        return !isShowingSplit || (split.canAddPane && !split.tabIDs.contains(tabID))
    }

    public func isInSplit(_ tabID: UUID) -> Bool { split.tabIDs.contains(tabID) }

    public func removeFromSplit(_ tabID: UUID) { split.remove(tabID) }

    /// Closes the pane the user is in; its tab stays open, and the next pane
    /// takes the selection so the rest of the split stays on screen.
    public func closeActivePane() {
        guard isShowingSplit, let current = tabs.selectedID else { return }
        let next = split.tabID(after: current)
        split.remove(current)
        if let next { tabs.select(next) }
    }

    public func closeSplit() { split.closeSplit() }

    /// Closes every tab in the split, which ends it.
    public func closeSplitTabs() {
        let ids = Set(split.tabIDs)
        split.closeSplit()
        tabs.closeTabs(ids)
    }

    /// Brings the split back on screen with the pane that was last used.
    public func showSplit(focusing tabID: UUID? = nil) {
        guard let target = tabID ?? split.tabIDs.first else { return }
        tabs.select(target)
    }

    public func focusPane(_ index: Int) {
        guard split.tabIDs.indices.contains(index), split.tabIDs[index] != tabs.selectedID else { return }
        tabs.select(split.tabIDs[index])
    }

    public func toggleActivePane() {
        if let next = split.tabID(after: tabs.selectedID) { tabs.select(next) }
    }

    public func toggleSplitOrientation() {
        split.orientation = split.orientation == .horizontal ? .vertical : .horizontal
    }
}
