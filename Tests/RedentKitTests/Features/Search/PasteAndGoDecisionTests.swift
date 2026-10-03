import Foundation
import Testing
@testable import RedentKit

@Suite("Paste and Go decision")
struct PasteAndGoDecisionTests {
    @Test("Empty or whitespace clipboard does nothing", arguments: ["", "   ", "\n", "\n\n  \t"])
    func emptyClipboard(_ text: String) {
        #expect(PasteAndGoDecision.action(for: text, using: .duckduckgo) == nil)
    }

    @Test("A host or URL is Paste and Go")
    func pasteAndGo() throws {
        let host = try #require(PasteAndGoDecision.action(for: "  example.com  ", using: .google))
        #expect(host.menuTitle == "Paste and Go")
        #expect(host.url.absoluteString == "https://example.com")

        let explicit = try #require(PasteAndGoDecision.action(for: "https://news.ycombinator.com", using: .google))
        guard case .go(let url) = explicit else {
            Issue.record("expected go")
            return
        }
        #expect(url.host() == "news.ycombinator.com")
    }

    @Test("Prose is Paste and Search")
    func pasteAndSearch() throws {
        let action = try #require(PasteAndGoDecision.action(for: "how to cook rice", using: .duckduckgo))
        #expect(action.menuTitle == "Paste and Search")
        #expect(action.url.host() == "duckduckgo.com")
        #expect(action.url.absoluteString.contains("q="))
    }

    @Test("Multi-line paste uses the first non-empty line")
    func firstLineWins() throws {
        let go = try #require(PasteAndGoDecision.action(
            for: "  \nhttps://example.com/path\nignored",
            using: .bing
        ))
        guard case .go(let url) = go else {
            Issue.record("expected go")
            return
        }
        #expect(url.absoluteString == "https://example.com/path")

        let search = try #require(PasteAndGoDecision.action(
            for: "\nswift concurrency\nsecond line",
            using: .duckduckgo
        ))
        guard case .search = search else {
            Issue.record("expected search")
            return
        }
    }
}
