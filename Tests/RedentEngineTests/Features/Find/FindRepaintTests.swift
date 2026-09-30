import Foundation
import RedentKit
import Testing
@testable import RedentEngine

/// WebKit repaints what leaves a Highlight, not what leaves the registry, so a
/// longer query once left the shorter one's paint on screen ("ge" still lit
/// after typing "gemini").
@Suite("Find repaint")
@MainActor
struct FindRepaintTests {
    @Test("A new query empties the previous highlight so its paint is cleared")
    func previousQueryHighlightIsEmptied() async throws {
        let tab = try await FindTestPage.saying("<p>Gemini usage over the time range</p>")
        let view = try #require(tab.webView)
        _ = await tab.findInPage("ge", forward: true)
        _ = try await view.callAsyncJavaScript(
            "window.previousFind = CSS.highlights.get('redent-find-all')",
            in: nil, contentWorld: PageScripts.contentWorld
        )

        #expect(await tab.findInPage("gemini", forward: true) == FindMatches(total: 1, current: 1))
        let leftover = try await view.callAsyncJavaScript(
            "return window.previousFind.size", in: nil, contentWorld: PageScripts.contentWorld
        ) as? Int
        #expect(leftover == 0)
    }
}
