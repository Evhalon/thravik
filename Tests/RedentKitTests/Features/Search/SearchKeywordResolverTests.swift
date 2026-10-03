import Foundation
import Testing
@testable import RedentKit

@Suite("Search keyword queries")
struct SearchKeywordResolverTests {
    private let youtube = CustomSearchEngine(
        name: "YouTube",
        keyword: "yt",
        template: "https://www.youtube.com/results?search_query=%s"
    )

    @Test("Keyword plus a space plus a query selects that engine")
    func parsesKeywordQuery() throws {
        let match = try #require(SearchKeywordResolver.match(in: "  YT  funny cats ", engines: [youtube]))
        #expect(match.engine.id == youtube.id)
        #expect(match.query == "funny cats")
        let url = try #require(AddressResolver.resolve(
            "yt funny cats",
            using: SearchRouting(engine: .duckduckgo, customEngines: [youtube])
        ))
        #expect(url.host() == "www.youtube.com")
        #expect(url.absoluteString.contains("funny%20cats") || url.absoluteString.contains("funny"))
    }

    @Test("A keyword alone, or an unknown keyword, is not a bang search")
    func rejectsIncomplete() {
        #expect(SearchKeywordResolver.match(in: "yt", engines: [youtube]) == nil)
        #expect(SearchKeywordResolver.match(in: "yt ", engines: [youtube]) == nil)
        #expect(SearchKeywordResolver.match(in: "g cats", engines: [youtube]) == nil)
        let url = AddressResolver.resolve("yt", using: SearchRouting(engine: .google, customEngines: [youtube]))
        #expect(url?.host() == "www.google.com")
    }

    @Test("Addresses are never read as keyword searches")
    func addressesStayAddresses() {
        let local = CustomSearchEngine(name: "Local", keyword: "localhost", template: "https://s.example/?q=%s")
        let routing = SearchRouting(engine: .google, customEngines: [youtube, local])
        #expect(AddressResolver.resolve("yt.com", using: routing)?.absoluteString == "https://yt.com")
        #expect(AddressResolver.resolve("localhost:3000", using: routing)?.absoluteString == "https://localhost:3000")
        #expect(AddressResolver.resolve("https://yt.com/a b", using: routing)?.host() != "www.youtube.com")
    }
}
