import Foundation
import RedentKit

/// Chrome visibility: tab strip, sidebar, focus mode, and where a new tab's
/// caret must land.
extension BrowserModel {
    /// Whether the tab strip is on screen right now, accounting for focus mode.
    public var showsTabStrip: Bool { settings.isTabStripVisible && !isFocusMode }

    public var isSidebarVisible: Bool { showsTabStrip && settings.tabLayout == .sidebar }

    public func toggleTabStrip() {
        settings.isTabStripVisible.toggle()
    }

    public func toggleTabLayout() {
        settings.tabLayout = settings.tabLayout == .sidebar ? .top : .sidebar
    }

    public func toggleFocusMode() {
        isFocusMode.toggle()
    }

    public func toggleSidebar() {
        if isSidebarVisible {
            settings.tabLayout = .top
            return
        }
        isFocusMode = false
        settings.isTabStripVisible = true
        settings.tabLayout = .sidebar
    }

    public func openNewTab() {
        tabs.newTab(url: nil)
        requestCenterSearchFocus()
    }

    func requestCenterSearchFocus() {
        address.finishEditing()
        centerSearchFocusEpoch &+= 1
    }
}

extension BrowserModel {
    /// The Space the window is showing. Bookmarks, saved logins and the
    /// new-tab page are all scoped to it.
    public var currentSpaceID: UUID? { tabs.session.selectedSpaceID }

    /// Space names by id, for screens that list more than one profile's data.
    public var spaceNames: [UUID: String] {
        Dictionary(tabs.session.spaces.map { ($0.id, $0.name) }, uniquingKeysWith: { first, _ in first })
    }

    /// Drag reorder: `sourceID` was dropped on the row showing `targetID`.
    public func reorderTab(_ sourceID: UUID, onto targetID: UUID) {
        guard let move = TabDropPlacement.move(sourceID, onto: targetID, in: tabs.visibleTabs.map(\.id)) else {
            return
        }
        tabs.move(fromOffsets: move.offsets, toOffset: move.to)
    }
}
