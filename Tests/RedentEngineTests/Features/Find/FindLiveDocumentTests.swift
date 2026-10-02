import Foundation
import RedentKit
import Testing
import WebKit
@testable import RedentEngine

@Suite("Find document changes and active matches")
@MainActor
struct FindLiveDocumentTests {
    @Test("Stepping includes content added after the initial query")
    func rescansDynamicContent() async throws {
        let tab = try await FindTestPage.saying("<p id=first>needle one</p><p>needle two</p>")
        let view = try #require(tab.webView)
        #expect(await tab.findInPage("needle", forward: true) == FindMatches(total: 2, current: 1))
        _ = try await view.evaluateJavaScript("document.body.insertAdjacentHTML('beforeend','<p>needle three</p>')")

        #expect(await tab.findInPage("needle", forward: true) == FindMatches(total: 3, current: 2))
        #expect(await tab.findInPage("needle", forward: true) == FindMatches(total: 3, current: 3))
        _ = try await view.evaluateJavaScript("document.getElementById('first').remove()")
        #expect(await tab.findInPage("needle", forward: true) == FindMatches(total: 2, current: 1))
    }

    @Test("Refining a query preserves the current occurrence")
    func preservesCurrentOccurrenceWhileTyping() async throws {
        let tab = try await FindTestPage.saying("<p>needle one</p><p>needle two</p><p>needle three</p>")
        _ = await tab.findInPage("need", forward: true)
        _ = await tab.findInPage("need", forward: true)

        #expect(await tab.findInPage("needle", forward: true) == FindMatches(total: 3, current: 2))
    }

    @Test("Deleting the query's first letter preserves its current occurrence")
    func preservesOverlappingOccurrenceWhileEditing() async throws {
        let tab = try await FindTestPage.saying("<p>needle one</p><p>needle two</p><p>needle three</p>")
        _ = await tab.findInPage("needle", forward: true)
        _ = await tab.findInPage("needle", forward: true)
        #expect(await tab.findInPage("eedle", forward: true) == FindMatches(total: 3, current: 2))
    }

    @Test("Refresh does not step, and deactivation leaves all highlights")
    func separatesScanningFromActivation() async throws {
        let tab = try await FindTestPage.saying("<p>needle one</p><p>needle two</p>")
        let view = try #require(tab.webView)
        _ = await tab.findInPage("needle", forward: true)
        _ = try await view.callAsyncJavaScript(
            "window.redentFindRefresh('needle'); window.redentFindActivate(-1); return null",
            in: nil, contentWorld: PageScripts.contentWorld
        )
        let counts = try await view.callAsyncJavaScript(
            "return [CSS.highlights.get('redent-find-all').size, CSS.highlights.has('redent-find-active')]",
            in: nil, contentWorld: PageScripts.contentWorld
        ) as? [Any]

        #expect(counts?.first as? Int == 2)
        #expect(counts?.last as? Bool == false)
    }

    @Test("Deleting the query retires all previous highlights")
    func emptyQueryClearsSession() async throws {
        let tab = try await FindTestPage.saying("<p>needle</p>")
        let view = try #require(tab.webView)
        _ = await tab.findInPage("needle", forward: true)
        #expect(await tab.findInPage("", forward: true) == .empty)
        let count = try await view.callAsyncJavaScript(
            "return CSS.highlights.size", in: nil, contentWorld: PageScripts.contentWorld
        ) as? Int
        #expect(count == 0)
    }

    @Test("The first backward request starts with the last visible match")
    func startsBackwardAtLastVisibleMatch() async throws {
        let tab = try await FindTestPage.saying("<p>needle one</p><p>needle two</p><p>needle three</p>")
        #expect(await tab.findInPage("needle", forward: false) == FindMatches(total: 3, current: 3))
    }
}
