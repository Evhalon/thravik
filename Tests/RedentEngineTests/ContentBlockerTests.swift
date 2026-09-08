import Foundation
import Testing
import WebKit
@testable import RedentEngine

@Suite("Content blocker")
@MainActor
struct ContentBlockerTests {
    @Test("YouTube's own page is excepted so mid-roll ads cannot kill the player")
    func youtubeIsExcepted() throws {
        let last = try #require(parsedRules().last)
        let action = try #require(last["action"] as? [String: String])
        let trigger = try #require(last["trigger"] as? [String: Any])
        let top = try #require(trigger["if-top-url"] as? [String])
        #expect(action["type"] == "ignore-previous-rules")
        #expect(top.contains { $0.contains("youtube\\.com") })
        #expect(top.contains { $0.contains("netflix\\.com") })
    }

    @Test("Ad networks are listed before the exception")
    func adsRemain() throws {
        let json = try #require(ContentBlocker.ruleListJSON)
        #expect(json.contains("doubleclick"))
        #expect(json.contains("googlesyndication"))
        #expect(json.contains("taboola"))
        #expect(json.contains("ignore-previous-rules"))
    }

    @Test("Cosmetic hide covers leftover ad slots")
    func hidesAdSlots() throws {
        let hide = try #require(parsedRules().first { rule in
            let action = rule["action"] as? [String: String]
            return action?["type"] == "css-display-none"
        })
        let action = try #require(hide["action"] as? [String: String])
        #expect(action["selector"]?.contains("adsbygoogle") == true)
        #expect(action["selector"]?.contains("div-gpt-ad") == true)
    }

    @Test("Ad domains are anchored, not substring matches")
    func domainFiltersAreAnchored() {
        let filter = ContentBlockList.domainFilter("doubleclick.net")
        #expect(filter.hasPrefix("^https?://"))
        #expect(filter.contains("doubleclick\\.net"))
        #expect(!filter.hasPrefix(".*"))
    }

    @Test("Ad networks are blocked on every load; trackers only as third-party")
    func loadTypeSplit() throws {
        let rules = try parsedRules()
        #expect(loadType(in: rules, matching: "doubleclick") == nil)
        #expect(loadType(in: rules, matching: "google-analytics") == ["third-party"])
    }

    @Test("The bundled catalog still compiles")
    func listCompiles() async throws {
        let json = try #require(ContentBlocker.ruleListJSON)
        let identifier = "app.redent.browser.blocklist.test"
        let store = try #require(WKContentRuleListStore.default())
        let list = try await store.compileContentRuleList(
            forIdentifier: identifier, encodedContentRuleList: json
        )
        try await store.removeContentRuleList(forIdentifier: identifier)
        #expect(list != nil)
    }

    @Test("The catalog covers a Brave-sized network set")
    func catalogIsSubstantial() throws {
        let catalog = try #require(ContentBlockCatalog.load())
        #expect(catalog.adDomains.count >= 100)
        #expect(catalog.trackerDomains.count >= 30)
        #expect(catalog.adDomains.contains("doubleclick.net"))
        #expect(catalog.trackerDomains.contains("google-analytics.com"))
        #expect(!catalog.adDomains.contains("t.co"))
        #expect(!catalog.trackerDomains.contains("t.co"))
    }

    private func parsedRules() throws -> [[String: Any]] {
        let json = try #require(ContentBlocker.ruleListJSON)
        let data = try #require(json.data(using: .utf8))
        return try #require(JSONSerialization.jsonObject(with: data) as? [[String: Any]])
    }

    private func loadType(in rules: [[String: Any]], matching needle: String) -> [String]? {
        for rule in rules {
            guard let trigger = rule["trigger"] as? [String: Any],
                  let filter = trigger["url-filter"] as? String,
                  filter.contains(needle)
            else { continue }
            return trigger["load-type"] as? [String]
        }
        return nil
    }
}
