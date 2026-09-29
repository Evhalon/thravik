import Foundation
import RedentKit
import Testing
@testable import RedentUI

@MainActor
@Suite("Sidebar navigation")
struct SidebarNavigationTests {
    @Test("Collapsing the sidebar preserves its layout and restores it on the next toggle")
    func collapsePreservesSidebarLayout() {
        let model = makeTestBrowserModel()
        model.settings.setNavigationBarHidden(true)
        model.address.beginEditing(with: nil)

        model.toggleSidebar()

        #expect(!model.isSidebarVisible)
        #expect(model.settings.tabLayout == .sidebar)
        #expect(model.usesSidebarNavigation)
        #expect(!model.showsNavigationBar)
        #expect(!model.address.isEditing)
        model.toggleSidebar()
        #expect(model.isSidebarVisible)
    }

    @Test("Top tabs keep their navigation, while focus mode hides both")
    func layoutAndFocusKeepNavigationReachable() {
        let model = makeTestBrowserModel()
        model.settings.setNavigationBarHidden(true)
        model.settings.tabLayout = .top
        #expect(model.showsNavigationBar)
        #expect(!model.usesSidebarNavigation)
        model.toggleFocusMode()
        #expect(!model.showsNavigationBar)
        #expect(!model.showsTabStrip)
        model.toggleTabStrip()
        #expect(!model.isFocusMode)
        #expect(model.showsTabStrip)
    }

    @Test("⌘L reopens hidden sidebar navigation and prepares the full page address for focus")
    func addressShortcutRevealsSidebar() {
        let browser = FakeBrowser()
        let tab = InertTab()
        tab.url = URL(string: "https://example.com/path")
        browser.stubTabs = [tab]
        browser.selectedID = tab.id
        let model = makeTestBrowserModel(tabs: browser)
        model.settings.setNavigationBarHidden(true)
        model.toggleTabStrip()

        model.focusAddressBar()

        #expect(model.isSidebarVisible)
        #expect(!model.showsNavigationBar)
        #expect(model.address.isEditing)
        #expect(model.address.text == tab.url?.absoluteString)
        #expect(model.chrome.addressFocusEpoch == 1)
    }

    @Test("⌘L on a blank page reaches its search field without expanding the sidebar")
    func newTabKeepsSidebarCollapsed() {
        let model = makeTestBrowserModel()
        model.settings.setNavigationBarHidden(true)
        model.toggleTabStrip()
        model.focusAddressBar()
        #expect(!model.isSidebarVisible)
        #expect(model.centerSearchFocusEpoch == 1)
        #expect(model.chrome.addressFocusEpoch == 0)
    }
}
