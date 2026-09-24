import Foundation
import RedentKit
import Testing
import WebKit
@testable import RedentEngine

/// Find-in-page against a real web view, because everything that can break here
/// breaks below the view model: an overload picked by argument label, a script
/// missing from the bundle, a payload that does not survive the bridge.
@Suite("Find in page")
@MainActor
struct FindInPageTests {
    @Test("The page answers with the count and the position, not just a yes")
    func reportsEveryMatchAndWhereWeAre() async throws {
        let tab = try await pageSaying("<p>quick one</p><p>quick two</p><p>quick three</p>")

        #expect(await tab.findInPage("quick", forward: true) == FindMatches(total: 3, current: 1))
        #expect(await tab.findInPage("quick", forward: true) == FindMatches(total: 3, current: 2))
        #expect(await tab.findInPage("quick", forward: false) == FindMatches(total: 3, current: 1))
    }

    @Test("A query the page does not hold counts nothing")
    func missingQueryCountsNothing() async throws {
        let tab = try await pageSaying("<p>quick one</p>")
        #expect(await tab.findInPage("absent", forward: true) == .empty)
        #expect(await tab.findInPage("", forward: true) == .empty)
    }

    @Test("Find includes the page and starts with a matching foreground dialog field")
    func findsTheModalFieldAndTheDimmedPage() async throws {
        let tab = try await pageSaying("""
        <p>306204 in the page behind</p>
        <div role="dialog" aria-modal="true"><input value="#306204 in the modal"></div>
        """)

        #expect(await tab.findInPage("306204", forward: true) == FindMatches(total: 2, current: 2))
        let marked = try await tab.webView?.callAsyncJavaScript(
            "return document.querySelector('input').classList.contains('redent-find-control-active')",
            in: nil, contentWorld: PageScripts.contentWorld
        ) as? Bool
        #expect(marked == true)

        tab.clearFindHighlight()
        try await Task.sleep(for: .milliseconds(50))
        let cleared = try await tab.webView?.evaluateJavaScript(
            "document.querySelector('input').classList.contains('redent-find-control-active')"
        ) as? Bool
        #expect(cleared == false)
    }

    @Test("The topmost dialog starts find, then every match remains reachable")
    func startsOnTheFrontDialogAndCyclesEveryMatch() async throws {
        let tab = try await pageSaying("""
        <div role="dialog" style="position:fixed;z-index:10"><input value="306204 behind"></div>
        <div role="dialog" style="position:fixed;z-index:20"><input value="306204 front"></div>
        """)

        #expect(await tab.findInPage("306204", forward: true) == FindMatches(total: 2, current: 2))
        #expect(await tab.findInPage("306204", forward: true) == FindMatches(total: 2, current: 1))
    }

    @Test("Matches are painted, and clearing puts the page back as it was")
    func highlightsAreLitAndPutOut() async throws {
        let tab = try await pageSaying("<p>quick one</p><p>quick two</p>")
        _ = await tab.findInPage("quick", forward: true)
        #expect(try await highlightCount(in: tab) == 2)

        tab.clearFindHighlight()
        try await Task.sleep(for: .milliseconds(50))
        #expect(try await highlightCount(in: tab) == 0)
        // The page keeps the DOM it started with: the highlights are ranges,
        // never wrapper elements.
        #expect(try await tab.webView?.evaluateJavaScript("document.querySelectorAll('span').length") as? Int == 0)
    }

    @Test("An older keystroke cannot repaint over the current query")
    func staleQueryCannotRepaint() async throws {
        let tab = try await pageSaying("<p>s elsewhere, then stock here</p>")
        let view = try #require(tab.webView)
        let script = "return window.redentFind(query, true, requestID)"

        _ = try await view.callAsyncJavaScript(
            script, arguments: ["query": "stock", "requestID": 2],
            in: nil, contentWorld: PageScripts.contentWorld
        )
        _ = try await view.callAsyncJavaScript(
            script, arguments: ["query": "s", "requestID": 1],
            in: nil, contentWorld: PageScripts.contentWorld
        )

        #expect(try await allHighlightRangeCount(in: tab) == 1)
    }

    /// The all-matches highlight and the active one, or neither.
    private func highlightCount(in tab: WebTab) async throws -> Int {
        let value = try await tab.webView?.callAsyncJavaScript(
            "return CSS.highlights.size",
            in: nil,
            contentWorld: PageScripts.contentWorld
        )
        return value as? Int ?? -1
    }

    private func allHighlightRangeCount(in tab: WebTab) async throws -> Int {
        let value = try await tab.webView?.callAsyncJavaScript(
            "return CSS.highlights.get('redent-find-all').size",
            in: nil,
            contentWorld: PageScripts.contentWorld
        )
        return value as? Int ?? -1
    }

    private func pageSaying(_ body: String) async throws -> WebTab {
        try await FindTestPage.saying(body)
    }
}
