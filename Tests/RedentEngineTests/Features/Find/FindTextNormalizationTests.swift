import Foundation
import RedentKit
import Testing
import WebKit
@testable import RedentEngine

@Suite("Find rendered text normalization")
@MainActor
struct FindTextNormalizationTests {
    @Test("Inline text is searchable across formatting and collapsed whitespace")
    func matchesRenderedInlineSentence() async throws {
        let tab = try await FindTestPage.saying("""
        <p>Hello
          <strong>brave</strong>\t<span>world</span></p>
        <p>Hello&nbsp;<em>brave</em>&nbsp;world</p>
        """)

        #expect(await tab.findInPage("hello brave world", forward: true) == FindMatches(total: 2, current: 1))
        #expect(try await highlightedText(in: tab).contains("brave") == true)
    }

    @Test("Layout determines boundaries, including custom inline elements and line breaks")
    func followsLayoutInsteadOfTagNames() async throws {
        let tab = try await FindTestPage.saying("""
        <p>hello <x-word style="display:inline">brave</x-word> world</p>
        <p>hello<br>brave world</p>
        <span style="display:block">hello</span><span style="display:block">brave world</span>
        """)

        #expect(await tab.findInPage("hello brave world", forward: true) == FindMatches(total: 2, current: 1))
        #expect(await tab.findInPage("hellobrave", forward: true) == .empty)
    }

    @Test("Unicode folding keeps highlights aligned with the original text")
    func normalizesCaseAndAccentsWithoutMovingRanges() async throws {
        let tab = try await FindTestPage.saying("<p>İstanbul Café Cafe\u{301} 😀Needle</p>")

        #expect(await tab.findInPage("istanbul", forward: true) == FindMatches(total: 1, current: 1))
        #expect(try await highlightedText(in: tab) == "İstanbul")
        #expect(await tab.findInPage("CAFE", forward: true) == FindMatches(total: 2, current: 1))
        #expect(try await highlightedText(in: tab) == "Café")
        #expect(await tab.findInPage("CAFE", forward: true) == FindMatches(total: 2, current: 2))
        #expect(try await highlightedText(in: tab) == "Cafe\u{301}")
        #expect(await tab.findInPage("needle", forward: true) == FindMatches(total: 1, current: 1))
        #expect(try await highlightedText(in: tab) == "Needle")
    }

    @Test("Regex punctuation is literal text")
    func searchesPunctuationLiterally() async throws {
        let tab = try await FindTestPage.saying("<p>[a+b] [axb] [a+b]</p>")
        #expect(await tab.findInPage("[a+b]", forward: true) == FindMatches(total: 2, current: 1))
    }

    @Test("Counters include every hit on long pages")
    func countsBeyondTheOldPaintingLimit() async throws {
        let body = String(repeating: "<span>needle </span>", count: 2_105)
        let tab = try await FindTestPage.saying(body)
        #expect(await tab.findInPage("needle", forward: true).total == 2_105)
    }

    @Test("A slot's fallback is searchable when it has no assigned content")
    func findsFallbackShadowSlot() async throws {
        let tab = try await FindTestPage.saying("""
        <x-card></x-card>
        <script>
        document.querySelector('x-card').attachShadow({mode:'open'}).innerHTML =
          '<slot>needle fallback</slot>';
        </script>
        """)
        #expect(await tab.findInPage("needle", forward: true) == FindMatches(total: 1, current: 1))
    }

    @Test("Discretionary hyphens do not break a word search")
    func ignoresSoftHyphens() async throws {
        let tab = try await FindTestPage.saying("<p>co&shy;operate</p>")
        #expect(await tab.findInPage("cooperate", forward: true) == FindMatches(total: 1, current: 1))
        #expect(try await highlightedText(in: tab) == "co\u{ad}operate")
    }

    private func highlightedText(in tab: WebTab) async throws -> String {
        let view = try #require(tab.webView)
        let value = try await view.callAsyncJavaScript(
            "return Array.from(CSS.highlights.get('redent-find-active') || []).map(r => r.toString()).join('')",
            in: nil, contentWorld: PageScripts.contentWorld
        )
        return value as? String ?? ""
    }
}
