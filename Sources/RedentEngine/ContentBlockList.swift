import Foundation

/// Builds the `WKContentRuleList` JSON Brave's default Shields resemble:
/// ad networks blocked on every load, trackers only as third-party, leftover
/// ad slots hidden, YouTube excepted so the player does not die.
@MainActor
enum ContentBlockList {
    static var encodedJSON: String? {
        guard let catalog = ContentBlockCatalog.load() else { return nil }
        return encode(rules(from: catalog))
    }

    static func rules(from catalog: ContentBlockCatalog) -> [[String: Any]] {
        var rules = catalog.adDomains.map { blockRule(domain: $0, thirdParty: false) }
        rules.append(contentsOf: catalog.trackerDomains.map { blockRule(domain: $0, thirdParty: true) })
        rules.append(contentsOf: catalog.pathFilters.map(pathRule))
        if !catalog.hideSelectors.isEmpty { rules.append(hideRule(catalog.hideSelectors)) }
        rules.append(mediaException)
        return rules
    }

    static func domainFilter(_ domain: String) -> String {
        let escaped = NSRegularExpression.escapedPattern(for: domain)
        return "^https?://([^/]*\\.)?\(escaped)[:/]"
    }

    private static func blockRule(domain: String, thirdParty: Bool) -> [String: Any] {
        var trigger: [String: Any] = ["url-filter": domainFilter(domain)]
        if thirdParty { trigger["load-type"] = ["third-party"] }
        return ["trigger": trigger, "action": ["type": "block"]]
    }

    private static func pathRule(_ pattern: String) -> [String: Any] {
        let filter = NSRegularExpression.escapedPattern(for: pattern)
        return [
            "trigger": ["url-filter": filter, "load-type": ["third-party"]],
            "action": ["type": "block"]
        ]
    }

    private static func hideRule(_ selectors: [String]) -> [String: Any] {
        [
            "trigger": ["url-filter": ".*"],
            "action": ["type": "css-display-none", "selector": selectors.joined(separator: ", ")]
        ]
    }

    private static var mediaException: [String: Any] {
        [
            "trigger": [
                "url-filter": ".*",
                "if-top-url": BrowserUserAgent.mediaTopURLFilters
            ],
            "action": ["type": "ignore-previous-rules"]
        ]
    }

    private static func encode(_ rules: [[String: Any]]) -> String? {
        guard JSONSerialization.isValidJSONObject(rules),
              let data = try? JSONSerialization.data(withJSONObject: rules)
        else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
