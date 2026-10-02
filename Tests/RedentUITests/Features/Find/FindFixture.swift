import Foundation
@testable import RedentUI

@MainActor
struct FindFixture {
    let browser: FakeBrowser
    let tabs: [InertTab]
    let model: BrowserModel

    init(tabCount: Int = 1) {
        let browser = FakeBrowser()
        tabs = (0..<tabCount).map { index in
            let tab = InertTab()
            tab.url = URL(string: "https://example.com/\(index)")
            return tab
        }
        browser.stubTabs = tabs
        browser.selectedID = tabs.first?.id
        self.browser = browser
        model = makeTestBrowserModel(tabs: browser)
    }
}
