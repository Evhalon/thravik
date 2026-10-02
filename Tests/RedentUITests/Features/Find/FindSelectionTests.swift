import RedentKit
import Testing
@testable import RedentUI

@Suite("Find selected page text")
@MainActor
struct FindSelectionTests {
    @Test("⌘F searches the selected page text and requests field selection")
    func selectedTextSeedsSearch() async {
        let fixture = FindFixture()
        fixture.tabs[0].selectedText = "selected words"
        fixture.model.chrome.findQuery = "previous query"
        fixture.model.showFindBar()
        #expect(fixture.model.chrome.isCapturingFindSelection)
        await fixture.model.chrome.findInFlight?.value

        #expect(fixture.model.chrome.findQuery == "selected words")
        #expect(fixture.tabs[0].findQueries == ["selected words"])
        #expect(fixture.model.chrome.findFocusEpoch == 2)
        #expect(!fixture.model.chrome.isCapturingFindSelection)
    }

    @Test("Repeated ⌘F requests focus without stepping or replacing the query")
    func repeatedFindKeepsQuery() async {
        let fixture = FindFixture()
        fixture.tabs[0].selectedText = "selected words"
        fixture.model.showFindBar()
        await fixture.model.chrome.findInFlight?.value
        let epoch = fixture.model.chrome.findFocusEpoch
        fixture.tabs[0].selectedText = "other words"
        fixture.model.showFindBar()
        await fixture.model.chrome.findInFlight?.value

        #expect(fixture.model.chrome.findQuery == "selected words")
        #expect(fixture.tabs[0].findQueries == ["selected words"])
        #expect(fixture.model.chrome.findFocusEpoch == epoch + 1)
    }

    @Test("Late page selection cannot overwrite a query the user typed")
    func typingWinsAgainstSelection() async {
        let fixture = FindFixture()
        let gate = FindResponseGate()
        fixture.tabs[0].selectionHandler = {
            _ = await gate.waitForResult()
            return "selected words"
        }
        fixture.model.showFindBar()
        await gate.waitUntilRequested()
        fixture.model.chrome.findQuery = "typed query"
        fixture.model.findQueryChanged()
        gate.reply(.empty)
        await fixture.model.chrome.findInFlight?.value

        #expect(fixture.model.chrome.findQuery == "typed query")
        #expect(fixture.tabs[0].findQueries == ["typed query"])
        #expect(fixture.model.chrome.findFocusEpoch == 1)
        #expect(!fixture.model.chrome.isCapturingFindSelection)
    }

    @Test("Selection from the previous tab is discarded after switching")
    func switchingWinsAgainstSelection() async {
        let fixture = FindFixture(tabCount: 2)
        let gate = FindResponseGate()
        fixture.tabs[0].selectionHandler = {
            _ = await gate.waitForResult()
            return "old page selection"
        }
        fixture.model.showFindBar()
        await gate.waitUntilRequested()
        fixture.browser.select(fixture.tabs[1].id)
        fixture.browser.onChange?()
        gate.reply(.empty)
        await fixture.model.chrome.findInFlight?.value

        #expect(fixture.model.chrome.findQuery.isEmpty)
        #expect(fixture.tabs[0].findQueries.isEmpty)
        #expect(fixture.tabs[1].findQueries.isEmpty)
        #expect(!fixture.model.chrome.isCapturingFindSelection)
        #expect(fixture.model.chrome.findFocusEpoch == 1)
    }

    @Test("An empty page selection still releases capture and focuses the find field")
    func emptySelectionEndsCapture() async {
        let fixture = FindFixture()
        fixture.model.showFindBar()
        #expect(fixture.model.chrome.isCapturingFindSelection)
        #expect(fixture.model.chrome.findFocusEpoch == 1)
        await fixture.model.chrome.findInFlight?.value

        #expect(!fixture.model.chrome.isCapturingFindSelection)
        #expect(fixture.model.chrome.findFocusEpoch == 2)
    }

    @Test("Closing during page selection capture cannot request focus afterward")
    func closingCancelsCaptureFocus() async {
        let fixture = FindFixture()
        let gate = FindResponseGate()
        fixture.tabs[0].selectionHandler = {
            _ = await gate.waitForResult()
            return "selected words"
        }
        fixture.model.showFindBar()
        await gate.waitUntilRequested()
        fixture.model.closeFindBar()
        gate.reply(.empty)
        await fixture.model.chrome.findInFlight?.value

        #expect(!fixture.model.chrome.isCapturingFindSelection)
        #expect(!fixture.model.chrome.isFindBarVisible)
        #expect(fixture.model.chrome.findFocusEpoch == 1)
    }
}
