import Testing
@testable import RedentEngine

@Suite("Find live document", .serialized)
@MainActor
struct FindLiveDocumentTests {
    @Test("New rendered text participates in native search")
    func findsDynamicText() async throws {
        let tab = try await FindTestPage.saying("<p>first needle</p>")
        _ = await tab.findInPage("needle", forward: true)
        _ = try await tab.webView?.evaluateJavaScript(
            "document.body.insertAdjacentHTML('beforeend', '<p>new target</p>')"
        )
        #expect(await tab.findInPage("target", forward: true) == .foundWithoutCount)
        #expect(await tab.selectedPageText() == "target")
    }

    @Test("Native search covers ordinary text and closed shadow text with the same query")
    func mixesDocumentAndClosedShadowMatches() async throws {
        let tab = try await FindTestPage.saying("""
        <p>needle in document</p><x-card></x-card>
        <script>
        customElements.define('x-card', class extends HTMLElement {
          constructor() {
            super();
            this.attachShadow({ mode: 'closed' }).innerHTML = '<p>needle in component</p>';
          }
        });
        </script>
        """)
        _ = await tab.findInPage("needle", forward: true)
        let selected = try await tab.webView?.callAsyncJavaScript(
            "return window.getSelection().anchorNode?.parentElement?.nodeName",
            in: nil, contentWorld: PageScripts.contentWorld
        ) as? String
        #expect(selected == "P")
        #expect(await tab.findInPage("needle", forward: true) == .foundWithoutCount)
        let host = try await tab.webView?.callAsyncJavaScript(
            "return window.getSelection().anchorNode?.parentElement?.nodeName",
            in: nil, contentWorld: PageScripts.contentWorld
        ) as? String
        #expect(host != "P")
    }
}
