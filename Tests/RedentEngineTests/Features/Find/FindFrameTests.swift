import Foundation
import RedentKit
import Testing
import WebKit
@testable import RedentEngine

@Suite("Find across frames", .serialized)
@MainActor
struct FindFrameTests {
    @Test("Frame matches interleave with the surrounding page and wrap in both directions")
    func followsDocumentOrder() async throws {
        let tab = try await FindTestPage.saying("""
        <p>needle before</p><iframe srcdoc="<p>needle inside</p>"></iframe><p>needle after</p>
        """)
        #expect(await tab.findInPage("needle", forward: true) == FindMatches(total: 3, current: 1))
        #expect(await tab.findInPage("needle", forward: true) == FindMatches(total: 3, current: 2))
        #expect(try await activeHighlights(in: tab, path: [0]) == 1)
        #expect(try await activeHighlights(in: tab, path: []) == 0)
        #expect(await tab.findInPage("needle", forward: true) == FindMatches(total: 3, current: 3))
        #expect(await tab.findInPage("needle", forward: true) == FindMatches(total: 3, current: 1))
        #expect(await tab.findInPage("needle", forward: false) == FindMatches(total: 3, current: 3))
    }

    @Test("An opaque-origin frame is searchable without sending the query through page messages")
    func searchesOpaqueOriginFrame() async throws {
        let tab = try await FindTestPage.saying("""
        <script>window.queries = []; addEventListener('message', e => { window.queries.push(JSON.stringify(e.data)); });</script>
        <iframe sandbox="allow-scripts" srcdoc="<p>unique framed text</p>"></iframe>
        """)
        #expect(await tab.findInPage("unique", forward: true) == FindMatches(total: 1, current: 1))
        let view = try #require(tab.webView)
        let leaked = try await view.evaluateJavaScript("window.queries.some(value => value.includes('unique'))") as? Bool
        #expect(leaked == false)
    }

    @Test("Hidden frames do not count, and removing a frame cannot leave stale matches")
    func excludesHiddenAndDetachedFrames() async throws {
        let tab = try await FindTestPage.saying("""
        <p>needle page</p><iframe id="visible" srcdoc="<p>needle visible</p>"></iframe>
        <iframe style="display:none" srcdoc="<p>needle hidden</p>"></iframe>
        """)
        #expect(await tab.findInPage("needle", forward: true) == FindMatches(total: 2, current: 1))
        let view = try #require(tab.webView)
        _ = try await view.evaluateJavaScript("document.getElementById('visible').remove()")
        #expect(await tab.findInPage("needle", forward: true) == FindMatches(total: 1, current: 1))
    }

    @Test("Changing the query clears old paint in a frame hidden between searches")
    func clearsHiddenFrameBeforeItReappears() async throws {
        let tab = try await FindTestPage.saying("""
        <p>needle page and other text</p><iframe id="child" srcdoc="<p>needle frame</p>"></iframe>
        """)
        #expect(await tab.findInPage("needle", forward: true) == FindMatches(total: 2, current: 1))
        let view = try #require(tab.webView)
        let frame = try #require(tab.pageFinder.frames.frame(at: [0]))
        let initial = try await view.callAsyncJavaScript(
            "return CSS.highlights.get('redent-find-all')?.size || 0",
            in: frame, contentWorld: PageScripts.contentWorld
        ) as? Int
        #expect(initial == 1)
        _ = try await view.evaluateJavaScript("document.getElementById('child').style.display = 'none'")

        #expect(await tab.findInPage("other", forward: true) == FindMatches(total: 1, current: 1))
        _ = try await view.evaluateJavaScript("document.getElementById('child').style.display = ''")
        let count = try await view.callAsyncJavaScript(
            "return CSS.highlights.size", in: frame, contentWorld: PageScripts.contentWorld
        ) as? Int
        #expect(count == 0)
    }

    @Test("An empty query clears highlights in every frame")
    func clearsEveryFrame() async throws {
        let tab = try await FindTestPage.saying("""
        <p>needle page</p><iframe srcdoc="<p>needle frame</p>"></iframe>
        """)
        _ = await tab.findInPage("needle", forward: true)
        _ = await tab.findInPage("", forward: true)
        let view = try #require(tab.webView)
        let frame = try #require(tab.pageFinder.frames.frame(at: [0]))
        let count = try await view.callAsyncJavaScript(
            "return CSS.highlights.size", in: frame, contentWorld: PageScripts.contentWorld
        ) as? Int
        #expect(count == 0)
        #expect(try await activeHighlights(in: tab, path: []) == 0)
    }

    private func activeHighlights(in tab: WebTab, path: [Int]) async throws -> Int {
        let view = try #require(tab.webView)
        let frame = path.isEmpty ? nil : tab.pageFinder.frames.frame(at: path)
        let count = try await view.callAsyncJavaScript(
            "return CSS.highlights.get('redent-find-active')?.size || 0",
            in: frame, contentWorld: PageScripts.contentWorld
        ) as? Int
        return count ?? -1
    }

    @Test("Removing the active frame starts at a remaining candidate without skipping it")
    func removingActiveFrameKeepsNavigationReachable() async throws {
        let tab = try await FindTestPage.saying("""
        <iframe id="frame" srcdoc="<p>needle frame</p>"></iframe><p>needle one</p><p>needle two</p>
        """)
        #expect(await tab.findInPage("needle", forward: true) == FindMatches(total: 3, current: 1))
        let view = try #require(tab.webView)
        _ = try await view.evaluateJavaScript("document.getElementById('frame').remove()")
        #expect(await tab.findInPage("needle", forward: true) == FindMatches(total: 2, current: 1))
    }

    @Test("Nested frames register their complete path and remain searchable")
    func searchesNestedFrame() async throws {
        let tab = try await FindTestPage.saying("""
        <iframe srcdoc="<p>needle outer</p><iframe srcdoc='&lt;p&gt;needle inner&lt;/p&gt;'></iframe>"></iframe>
        """)
        #expect(await tab.findInPage("needle", forward: true) == FindMatches(total: 2, current: 1))
        #expect(await tab.findInPage("needle", forward: true) == FindMatches(total: 2, current: 2))
        #expect(try await activeHighlights(in: tab, path: [0, 0]) == 1)
    }
}
