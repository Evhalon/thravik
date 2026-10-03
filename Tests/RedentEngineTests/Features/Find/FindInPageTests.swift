import RedentKit
import Testing
@testable import RedentEngine

@Suite("Find in page", .serialized)
@MainActor
struct FindInPageTests {
    @Test("Native find selects only the matching substring and wraps in both directions")
    func selectsAndCyclesMatches() async throws {
        let tab = try await FindTestPage.saying("<p id=one>Needle one</p><p id=two>needle two</p>")
        #expect(await tab.findInPage("needle", forward: true) == .foundWithoutCount)
        #expect(try await selection(in: tab) == ["Needle", "one"])
        _ = await tab.findInPage("needle", forward: true)
        #expect(try await selection(in: tab) == ["needle", "two"])
        _ = await tab.findInPage("needle", forward: true)
        #expect(try await selection(in: tab) == ["Needle", "one"])
        _ = await tab.findInPage("needle", forward: false)
        #expect(try await selection(in: tab) == ["needle", "two"])
    }

    @Test("Native find never paints the entire field or rewrites the page")
    func leavesPageMarkupAlone() async throws {
        let tab = try await FindTestPage.saying("<p>needle</p><input value='needle field'>")
        _ = await tab.findInPage("needle", forward: true)
        let markup = try await tab.webView?.evaluateJavaScript("document.body.innerHTML") as? String
        #expect(markup == "<p>needle</p><input value=\"needle field\">")
        let highlights = try await tab.webView?.callAsyncJavaScript(
            "return CSS.highlights.size", in: nil, contentWorld: PageScripts.contentWorld
        ) as? Int
        #expect(highlights == 0)
    }

    @Test("An absent query clears the previous native selection")
    func absentQueryClearsSelection() async throws {
        let tab = try await FindTestPage.saying("<p>needle</p>")
        _ = await tab.findInPage("needle", forward: true)
        #expect(await tab.findInPage("absent", forward: true) == .empty)
        #expect(try await selection(in: tab)?.first == "")
    }

    @Test("Closing find clears the selection after submitted native work finishes")
    func closingClearsInFlightFind() async throws {
        let tab = try await FindTestPage.saying("<p>needle</p>")
        let search = Task { await tab.findInPage("needle", forward: true) }
        await Task.yield()
        tab.clearFindHighlight()
        _ = await search.value
        let deadline = ContinuousClock.now + .seconds(5)
        while await tab.selectedPageText() != nil, ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(20))
        }
        #expect(try await selection(in: tab)?.first == "")
    }

    private func selection(in tab: WebTab) async throws -> [String]? {
        try await tab.webView?.callAsyncJavaScript(
            "const s = window.getSelection(); return [String(s), s.anchorNode?.parentElement?.id || ''];",
            in: nil, contentWorld: PageScripts.contentWorld
        ) as? [String]
    }
}
