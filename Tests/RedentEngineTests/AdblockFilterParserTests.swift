import Foundation
import Testing
import WebKit
@testable import RedentEngine

@Suite("Brave filter conversion")
struct AdblockFilterParserTests {
    @Test("Network and exception rules become WebKit rules, cosmetics stay out")
    func convertsSupportedRules() throws {
        let source = """
        [Adblock Plus 2.0]
        ||ads.example^
        ||metrics.example^$third-party
        @@||ads.example/allowed^
        ##.global-ad
        news.example##.site-only
        """
        let rules = try parse(source)
        #expect(rules.filter { action(in: $0) == "block" }.count == 2)
        #expect(action(in: rules[2]) == "ignore-previous-rules")
        #expect(!rules.contains { action(in: $0) == "css-display-none" })
    }

    @Test("Modifiers WebKit cannot express drop the filter instead of widening it")
    func skipsUnsupportedRules() {
        let source = """
        example.com##+js(abort-on-property-read, ad)
        ||imasdk.example^$script,redirect-rule=google-ima.js
        ||player.example^$csp=script-src 'none'
        ||video.example^$removeparam=utm_source
        ||cdn.example^$first-party
        ||cdn.example^$1p
        ||cdn.example^$badfilter
        ||site.example^$domain=a.example|~b.example
        """
        #expect(AdblockFilterParser().encodedRules(from: source) == nil)
    }

    @Test("Domain scopes become if-domain rather than a global block")
    func scopesToDomains() throws {
        let rule = try #require(parse("||ads.example^$domain=news.example|Blog.example").first)
        let trigger = try #require(rule["trigger"] as? [String: Any])
        #expect(trigger["if-domain"] as? [String] == ["*news.example", "*blog.example"])
    }

    @Test("Blocks never name media; typed filters keep their type")
    func mediaIsNeverBlocked() throws {
        let rules = try parse("||ads.example^\n||tag.example^$script,media")
        let types = rules.prefix(2).map { ($0["trigger"] as? [String: Any])?["resource-type"] as? [String] }
        #expect(types[0]?.contains("media") == false)
        #expect(types[1] == ["script"])
    }

    @Test("Every converted list ends with the media exceptions")
    func carriesMediaTail() throws {
        let rules = try parse("||ads.example^")
        let json = String(describing: rules)
        #expect(json.contains("imasdk"))
        let last = try #require(rules.last?["trigger"] as? [String: Any])
        #expect((last["if-top-url"] as? [String])?.contains { $0.contains("youtube") } == true)
    }

    @Test("A double-pipe path filter is anchored to the host, not the URL start")
    func anchorsHostPaths() throws {
        let rule = try #require(parse("||ads.example/banner*.js").first)
        let filter = try #require((rule["trigger"] as? [String: Any])?["url-filter"] as? String)
        #expect(filter.hasPrefix("^https?://([^/]*\\.)?ads\\.example\\/banner"))
    }

    @Test("Converted filters compile in WebKit")
    @MainActor
    func compilesInWebKit() async throws {
        let source = """
        ||ads.example^
        ||ads.example/path*.js|
        /banner/ad-
        ||tag.example^$script,xhr,subdocument,image,stylesheet,font,ping,websocket,other
        ||x.example^$~script,domain=news.example
        @@||ads.example/allowed^$media
        """
        let json = try #require(AdblockFilterParser().encodedRules(from: source))
        let store = try #require(WKContentRuleListStore.default())
        let identifier = "app.redent.browser.brave-parser.test"
        let list = try await store.compileContentRuleList(
            forIdentifier: identifier, encodedContentRuleList: json
        )
        try await store.removeContentRuleList(forIdentifier: identifier)
        #expect(list != nil)
    }

    private func parse(_ source: String) throws -> [[String: Any]] {
        let json = try #require(AdblockFilterParser().encodedRules(from: source))
        let data = try #require(json.data(using: .utf8))
        return try #require(JSONSerialization.jsonObject(with: data) as? [[String: Any]])
    }

    private func action(in rule: [String: Any]?) -> String? {
        (rule?["action"] as? [String: String])?["type"]
    }
}
