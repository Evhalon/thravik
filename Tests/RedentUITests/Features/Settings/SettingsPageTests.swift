import Foundation
import RedentKit
import Testing
@testable import RedentUI

@Suite("Settings page")
@MainActor
struct SettingsPageTests {
    @Test("Settings open as a page, never as a sheet")
    func opensAsPage() {
        let model = makeTestBrowserModel()
        model.sheet = .history
        model.showCommands()

        model.execute(.showScreen(.settings))

        #expect(model.showsSettings)
        #expect(model.sheet == nil)
        #expect(!model.showsCommandBar)
    }

    @Test("Other screens still arrive as sheets over the page")
    func otherScreensStaySheets() {
        let model = makeTestBrowserModel()
        model.showSettings()

        model.execute(.showScreen(.passwords))

        #expect(model.sheet == .passwords)
        #expect(model.showsSettings)
    }

    @Test("Clicking a tab, even the selected one, leaves Settings for its page")
    func selectingTabCloses() {
        let browser = FakeBrowser()
        let tab = InertTab()
        browser.stubTabs = [tab]
        let model = makeTestBrowserModel(tabs: browser)
        model.showSettings()

        model.selectTab(tab.id)

        #expect(!model.showsSettings)
        #expect(browser.selectionCalls == [tab.id])
    }

    @Test("Navigating somewhere leaves Settings")
    func navigatingCloses() throws {
        let model = makeTestBrowserModel()
        model.showSettings()

        model.navigate(to: try #require(URL(string: "https://example.com")))

        #expect(!model.showsSettings)
    }
}
