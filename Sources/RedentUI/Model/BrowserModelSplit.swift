import Foundation
import RedentKit

/// Split View from the window's side: which tab each pane shows, which pane the
/// chrome acts on, and the commands that change either.
extension BrowserModel {
    /// The tab the chrome acts on. In a split window that is the active pane's
    /// tab, not the window's selection — a keystroke must reach the page the
    /// user is looking at.
    public var selectedTab: (any BrowserTab)? {
        guard let id = split.activeTabID(primary: tabs.selectedID) else { return nil }
        return tabs.tabs.first { $0.id == id }
    }

    /// The tab the left (or top) pane renders, which is the window's selection.
    public var primaryTab: (any BrowserTab)? { tabs.selectedTab }

    /// The tab the right (or bottom) pane renders, if the window is split.
    public var secondaryTab: (any BrowserTab)? {
        guard let id = split.secondaryTabID else { return nil }
        return tabs.tabs.first { $0.id == id }
    }

    /// Puts the next tab in the Space beside the current one. Nothing to split
    /// with is not an error — it just does not split.
    public func splitWithNextTab() {
        let visible = tabs.visibleTabs.map(\.id)
        guard let primary = tabs.selectedID,
              let neighbour = visible.first(where: { $0 != primary }) else { return }
        split.split(with: neighbour, primary: primary)
    }

    public func splitWith(_ tabID: UUID) {
        split.split(with: tabID, primary: tabs.selectedID)
    }

    public func closeSplit() {
        split.closeSecondary()
    }

    public func toggleActivePane() {
        split.togglePane()
    }

    public func toggleSplitOrientation() {
        split.orientation = split.orientation == .horizontal ? .vertical : .horizontal
    }
}
