import Foundation
import RedentKit
import Testing
@testable import RedentUI

@Suite("Find counter")
@MainActor
struct FindCounterTests {
    private func windowOnAPage() -> (BrowserModel, InertTab) {
        let browser = FakeBrowser()
        let tab = InertTab()
        tab.url = URL(string: "https://example.com")
        browser.stubTabs = [tab]
        browser.selectedID = tab.id
        return (makeTestBrowserModel(tabs: browser), tab)
    }

    @Test("The page's count reaches the find bar")
    func countReachesTheBar() async {
        let (model, tab) = windowOnAPage()
        tab.findResult = FindMatches(total: 3, current: 1)
        model.chrome.findQuery = "quick"

        model.findNext()
        await model.chrome.findInFlight?.value

        #expect(model.chrome.findMatches == FindMatches(total: 3, current: 1))
        #expect(!model.chrome.findFailed)
        #expect(tab.findQueries == ["quick"])
    }

    @Test("A query nothing matches turns the field red")
    func missingQueryFails() async {
        let (model, tab) = windowOnAPage()
        tab.findResult = .empty
        model.chrome.findQuery = "absent"

        model.findNext()
        await model.chrome.findInFlight?.value

        #expect(model.chrome.findFailed)
    }

    @Test("A slower answer for an old query cannot replace the new one")
    func staleAnswerIsDropped() async {
        let (model, tab) = windowOnAPage()
        tab.findResult = FindMatches(total: 9, current: 1)
        model.chrome.findQuery = "qui"

        model.findNext()
        model.chrome.findQuery = "quick"
        await model.chrome.findInFlight?.value

        #expect(model.chrome.findMatches == nil)
    }

    @Test("Reopening the bar lights the page up again, and ⌘F twice does not step")
    func reopeningSearchesAgain() async {
        let (model, tab) = windowOnAPage()
        tab.findResult = FindMatches(total: 4, current: 1)
        model.chrome.findQuery = "quick"

        model.showFindBar()
        await model.chrome.findInFlight?.value
        #expect(tab.findQueries == ["quick"])

        model.showFindBar()
        await model.chrome.findInFlight?.value
        #expect(tab.findQueries == ["quick"])
    }

    @Test("Emptying the field drops the highlight rather than leaving it lit")
    func emptyQueryClearsTheHighlight() async {
        let (model, tab) = windowOnAPage()
        tab.findResult = FindMatches(total: 2, current: 1)
        model.chrome.findQuery = "quick"
        model.findNext()
        await model.chrome.findInFlight?.value

        model.chrome.findQuery = ""
        model.findNext()

        #expect(model.chrome.findMatches == nil)
        #expect(tab.findHighlightClears == 1)
    }
}
