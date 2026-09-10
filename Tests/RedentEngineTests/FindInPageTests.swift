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

    /// The all-matches highlight and the active one, or neither.
    private func highlightCount(in tab: WebTab) async throws -> Int {
        let value = try await tab.webView?.callAsyncJavaScript(
            "return CSS.highlights.size",
            in: nil,
            contentWorld: PageScripts.contentWorld
        )
        return value as? Int ?? -1
    }

    private func pageSaying(_ body: String) async throws -> WebTab {
        let controller = TabController(
            session: BrowserSession(tabs: [TabSnapshot()], selectedTabID: nil),
            settings: BrowserSettings(),
            logger: QuietFindLogger()
        )
        let tab = try #require(controller.webTabs.first)
        tab.wake(loading: nil)
        let view = try #require(tab.webView)
        view.loadHTMLString("<body>\(body)</body>", baseURL: URL(string: "https://example.com"))
        for _ in 0..<200 {
            let ready = try? await view.callAsyncJavaScript(
                "return typeof window.redentFind === 'function' && !!document.body",
                in: nil,
                contentWorld: PageScripts.contentWorld
            ) as? Bool
            if ready == true { return tab }
            try await Task.sleep(for: .milliseconds(20))
        }
        Issue.record("The find script never reached the page")
        return tab
    }
}

private struct QuietFindLogger: EventLogging {
    func debug(_ message: @autoclosure () -> String) {}
    func notice(_ message: @autoclosure () -> String) {}
    func error(_ message: @autoclosure () -> String) {}
}
