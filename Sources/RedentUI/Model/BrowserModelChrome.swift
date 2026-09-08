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

    /// Everything modal the window is showing, torn down at once.
    ///
    /// Quitting is the caller that matters: AppKit swallows `terminate` while a
    /// sheet is attached, and this binding is what puts it there — so it has to
    /// be cleared, not fought.
    public func dismissPresentations() {
        sheet = nil
        dismissCommands()
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

    /// Commits a live drag: `order` is what the user saw when they let go, and
    /// the tab's cluster membership follows what it was dropped between.
    public func commitTabDrag(_ id: UUID, order: [UUID]) {
        let outcome = TabDropGrouping.outcome(
            moved: id,
            order: order,
            tabs: tabs.session.tabs,
            groups: tabs.session.groups
        )
        tabs.applyOrder(order)
        switch outcome {
        case .keep: return
        case .leave: try? tabs.perform(.moveTabToGroup(tabID: id, groupID: nil))
        case .join(let groupID): try? tabs.perform(.moveTabToGroup(tabID: id, groupID: groupID))
        }
    }
}
