import RedentKit
import Testing
@testable import RedentUI

@MainActor
@Suite("Tab layout switching")
struct TabLayoutTests {
    @Test("The layout command switches sidebar and top tabs in both directions", arguments: TabLayout.allCases)
    func togglesLayout(initialLayout: TabLayout) {
        let browser = FakeBrowser()
        let tab = InertTab()
        browser.stubTabs = [tab]
        browser.selectedID = tab.id
        let model = makeTestBrowserModel(tabs: browser)
        model.settings.tabLayout = initialLayout

        model.toggleTabLayout()

        #expect(model.settings.tabLayout == (initialLayout == .sidebar ? .top : .sidebar))
        #expect(model.showsTabStrip)
        #expect(model.isSidebarVisible == (initialLayout == .top))
        #expect(browser.selectedID == tab.id)

        model.toggleTabLayout()

        #expect(model.settings.tabLayout == initialLayout)
        #expect(browser.selectedID == tab.id)
    }
}
