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
