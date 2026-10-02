import Foundation
import RedentKit
import Testing
@testable import RedentUI

@Suite("Find page lifecycle")
@MainActor
struct FindLifecycleTests {
    @Test("Closing cancels a pending query and returns focus to the page")
    func closingCancelsDebounce() async {
        let fixture = FindFixture()
        fixture.model.showFindBar()
        await fixture.model.chrome.findInFlight?.value
        fixture.model.chrome.findQuery = "needle"
        fixture.model.findQueryChanged()
        fixture.model.closeFindBar()
        await fixture.model.chrome.findInFlight?.value

        #expect(fixture.tabs[0].findQueries.isEmpty)
        #expect(fixture.tabs[0].pageFocusRequests == 1)
        #expect(fixture.model.chrome.findMatches == nil)
        #expect(fixture.model.chrome.findQuery == "needle")
    }

    @Test("A result arriving after Escape cannot reopen the counter")
    func closingDropsRunningAnswer() async {
        let fixture = FindFixture()
        let gate = FindResponseGate()
        fixture.tabs[0].findHandler = { _, _ in await gate.waitForResult() }
        fixture.model.chrome.findQuery = "needle"
        fixture.model.findNext()
        await gate.waitUntilRequested()
        fixture.model.closeFindBar()
        gate.reply(FindMatches(total: 3, current: 1))
        await fixture.model.chrome.findInFlight?.value

        #expect(!fixture.model.chrome.isFindBarVisible)
        #expect(fixture.model.chrome.findMatches == nil)
        #expect(fixture.tabs[0].findHighlightClears == 1)
    }

    @Test("Loading clears old counts and completion searches the new page")
    func navigationReappliesSearch() async {
        let fixture = FindFixture()
        let tab = fixture.tabs[0]
        tab.findResult = FindMatches(total: 2, current: 1)
        fixture.model.chrome.findQuery = "needle"
        fixture.model.findNext()
        await fixture.model.chrome.findInFlight?.value

        tab.isLoading = true
        fixture.model.findPageContextChanged()
        #expect(fixture.model.chrome.findMatches == nil)
        #expect(tab.findQueries == ["needle"])
        tab.url = URL(string: "https://example.com/new")
        fixture.model.pageContextChanged()
        tab.findResult = FindMatches(total: 5, current: 1)
        tab.isLoading = false
        fixture.model.findPageContextChanged()
        await fixture.model.chrome.findInFlight?.value

        #expect(tab.findQueries == ["needle", "needle"])
        #expect(fixture.model.chrome.findMatches == FindMatches(total: 5, current: 1))
    }

    @Test("An empty new tab hides find while retaining the last query")
    func emptyTabHidesFind() async {
        let fixture = FindFixture(tabCount: 2)
        fixture.model.chrome.findQuery = "needle"
        fixture.model.findNext()
        await fixture.model.chrome.findInFlight?.value
        fixture.tabs[1].url = nil
        fixture.browser.select(fixture.tabs[1].id)
        fixture.browser.onChange?()

        #expect(!fixture.model.chrome.isFindBarVisible)
        #expect(fixture.model.chrome.findQuery == "needle")
        #expect(fixture.model.chrome.findMatches == nil)
        #expect(fixture.tabs[0].findHighlightClears == 1)
    }

    @Test("⌘G can reopen the previous query after the find bar is closed")
    func nextReopensPreviousSearch() async {
        let fixture = FindFixture()
        fixture.model.chrome.findQuery = "needle"
        fixture.model.findNext()
        await fixture.model.chrome.findInFlight?.value
        fixture.model.closeFindBar()
        #expect(fixture.model.canFindNext)
        fixture.model.findNext(forward: false)
        await fixture.model.chrome.findInFlight?.value

        #expect(fixture.model.chrome.isFindBarVisible)
        #expect(fixture.tabs[0].findDirections == [true, false])
    }

    @Test("Closing and reopening the same query cannot revive its previous answer")
    func reopeningDropsPreviousSession() async {
        let fixture = FindFixture()
        let gate = FindResponseGate()
        fixture.tabs[0].findHandler = { _, _ in await gate.waitForResult() }
        fixture.model.chrome.findQuery = "needle"
        fixture.model.findNext()
        await gate.waitUntilRequested()
        fixture.model.closeFindBar()
        fixture.tabs[0].findHandler = nil
        fixture.tabs[0].findResult = FindMatches(total: 2, current: 1)
        fixture.model.showFindBar()
        gate.reply(FindMatches(total: 9, current: 1))
        await fixture.model.chrome.findInFlight?.value

        #expect(fixture.model.chrome.findMatches == FindMatches(total: 2, current: 1))
    }

    @Test("A reload at the same URL invalidates a running search")
    func reloadDropsPreviousDocument() async {
        let fixture = FindFixture()
        let tab = fixture.tabs[0]
        let gate = FindResponseGate()
        tab.findHandler = { _, _ in await gate.waitForResult() }
        fixture.model.chrome.findQuery = "needle"
        fixture.model.findNext()
        await gate.waitUntilRequested()
        tab.findHandler = nil
        tab.findResult = FindMatches(total: 3, current: 1)
        tab.isLoading = true
        fixture.model.findPageContextChanged()
        tab.isLoading = false
        fixture.model.findPageContextChanged()
        gate.reply(FindMatches(total: 9, current: 1))
        await fixture.model.chrome.findInFlight?.value

        #expect(fixture.model.chrome.findMatches == FindMatches(total: 3, current: 1))
    }
}
