import RedentKit
import Testing
@testable import RedentUI

@Suite("Find request ordering")
@MainActor
struct FindOrderingTests {
    @Test("Rapid next and previous commands all reach the page, in order")
    func rapidStepsArePreserved() async {
        let fixture = FindFixture()
        let tab = fixture.tabs[0]
        let gate = FindResponseGate()
        tab.findHandler = { _, _ in await gate.waitForResult() }
        fixture.model.chrome.findQuery = "needle"
        fixture.model.findNext()
        await gate.waitUntilRequested()
        tab.findHandler = nil
        tab.findResult = FindMatches(total: 4, current: 2)

        fixture.model.findNext()
        fixture.model.findNext(forward: false)
        #expect(tab.findQueries == ["needle"])
        gate.reply(FindMatches(total: 4, current: 1))
        await fixture.model.chrome.findInFlight?.value

        #expect(tab.findQueries == ["needle", "needle", "needle"])
        #expect(tab.findDirections == [true, true, false])
        #expect(fixture.model.chrome.findMatches == FindMatches(total: 4, current: 2))
    }

    @Test("Changing the query removes the previous count immediately")
    func editingDropsPreviousCount() {
        let fixture = FindFixture()
        fixture.model.chrome.findQuery = "old"
        fixture.model.chrome.findMatches = .empty
        fixture.model.chrome.findQuery = "new"

        #expect(fixture.model.chrome.findMatches == nil)
        #expect(!fixture.model.chrome.findFailed)
    }

    @Test("Returning to an earlier query cannot revive its old answer")
    func repeatedQueryDropsObsoleteAnswer() async {
        let fixture = FindFixture()
        let tab = fixture.tabs[0]
        let gate = FindResponseGate()
        tab.findHandler = { _, _ in await gate.waitForResult() }
        fixture.model.chrome.findQuery = "needle"
        fixture.model.findNext()
        await gate.waitUntilRequested()
        tab.findHandler = nil
        tab.findResult = FindMatches(total: 2, current: 1)

        fixture.model.chrome.findQuery = "other"
        fixture.model.findQueryChanged()
        fixture.model.chrome.findQuery = "needle"
        fixture.model.findQueryChanged()
        gate.reply(FindMatches(total: 9, current: 1))
        await fixture.model.chrome.findInFlight?.value

        #expect(tab.findQueries == ["needle", "needle"])
        #expect(fixture.model.chrome.findMatches == FindMatches(total: 2, current: 1))
    }

    @Test("A result from a previous tab cannot replace the current page's result")
    func oldTabAnswerIsDropped() async {
        let fixture = FindFixture(tabCount: 2)
        let gate = FindResponseGate()
        fixture.tabs[0].findHandler = { _, _ in await gate.waitForResult() }
        fixture.tabs[1].findResult = FindMatches(total: 3, current: 1)
        fixture.model.chrome.findQuery = "needle"
        fixture.model.findNext()
        await gate.waitUntilRequested()

        fixture.browser.select(fixture.tabs[1].id)
        fixture.browser.onChange?()
        #expect(fixture.model.chrome.findMatches == nil)
        #expect(fixture.tabs[0].findHighlightClears == 1)
        gate.reply(FindMatches(total: 9, current: 1))
        await fixture.model.chrome.findInFlight?.value

        #expect(fixture.tabs[1].findQueries == ["needle"])
        #expect(fixture.model.chrome.findMatches == FindMatches(total: 3, current: 1))
    }
}
