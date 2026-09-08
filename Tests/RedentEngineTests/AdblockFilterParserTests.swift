import Foundation
import Testing
import WebKit
@testable import RedentEngine

@Suite("Brave filter conversion")
struct AdblockFilterParserTests {
    @Test("Network, exception and cosmetic rules become WebKit rules")
    func convertsSupportedRules() throws {
        let source = """
        [Adblock Plus 2.0]
        ||ads.example^
        ||metrics.example^$third-party
        @@||ads.example/allowed^
        ##.global-ad
        news.example##.site-only
        """
        let json = try #require(AdblockFilterParser().encodedRules(from: source))
        let data = try #require(json.data(using: .utf8))
        let rules = try #require(JSONSerialization.jsonObject(with: data) as? [[String: Any]])
        #expect(rules.count == 4)
        #expect(action(in: rules.last) == "ignore-previous-rules")
        #expect(json.contains("third-party"))
        #expect(json.contains(".global-ad"))
        #expect(!json.contains(".site-only"))
    }

    @Test("Scriptlets and scoped rules are skipped safely")
    func skipsUnsupportedRules() throws {
        let source = """
        example.com##+js(abort-on-property-read, ad)
        ||example.com^$domain=example.org
        """
        #expect(AdblockFilterParser().encodedRules(from: source) == nil)
    }

    @Test("Brave Standard does not block first-party list matches")
    func usesStandardMode() throws {
        let json = try #require(AdblockFilterParser().encodedRules(from: "||ads.example^"))
        #expect(json.contains("third-party"))
        #expect(AdblockFilterParser().encodedRules(from: "||cdn.example^$first-party") == nil)
    }

    @Test("Converted filters compile in WebKit")
    @MainActor
    func compilesInWebKit() async throws {
        let source = "||ads.example^\n@@||ads.example/allowed^\n##.advertisement"
        let json = try #require(AdblockFilterParser().encodedRules(from: source))
        let store = try #require(WKContentRuleListStore.default())
        let identifier = "app.redent.browser.brave-parser.test"
        let list = try await store.compileContentRuleList(
            forIdentifier: identifier, encodedContentRuleList: json
        )
        try await store.removeContentRuleList(forIdentifier: identifier)
        #expect(list != nil)
    }

    private func action(in rule: [String: Any]?) -> String? {
        (rule?["action"] as? [String: String])?["type"]
    }
}
