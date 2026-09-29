import Foundation

/// Converts EasyList-syntax network filters into a `WKContentRuleList`.
///
/// Only third-party loads are blocked, as in Brave's Standard mode. Cosmetic
/// filters are left to the bundled list: the lists' generic hides lean on
/// `#@#` exceptions a content blocker cannot express, and without them they
/// blank out players and page furniture on sites they were never meant for —
/// while every one of them is a selector matched on every page.
struct AdblockFilterParser: Sendable {
    func encodedRules(from text: String) -> String? {
        var blocking = [[String: Any]]()
        var exceptions = [[String: Any]]()
        for rawLine in text.split(whereSeparator: \.isNewline) {
            guard let (rule, isException) = rule(from: String(rawLine)) else { continue }
            if isException { exceptions.append(rule) } else { blocking.append(rule) }
        }
        guard !blocking.isEmpty else { return nil }
        let rules = blocking + exceptions + MediaRuleExceptions.rules
        guard JSONSerialization.isValidJSONObject(rules),
              let data = try? JSONSerialization.data(withJSONObject: rules)
        else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func rule(from line: String) -> (rule: [String: Any], isException: Bool)? {
        let line = line.trimmingCharacters(in: .whitespaces)
        guard !line.isEmpty, !line.hasPrefix("!"), !line.hasPrefix("["),
              !line.contains("#"), !line.contains("$$") else { return nil }
        let isException = line.hasPrefix("@@")
        let body = isException ? String(line.dropFirst(2)) : line
        let parts = body.split(separator: "$", maxSplits: 1, omittingEmptySubsequences: false).map(String.init)
        guard let pattern = parts.first, let filter = urlFilter(pattern),
              let options = AdblockFilterOptions(parts.count == 2 ? parts[1] : nil, isException: isException)
        else { return nil }
        var trigger = options.triggerFields
        trigger["url-filter"] = filter
        if !isException { trigger["load-type"] = ["third-party"] }
        let action = isException ? "ignore-previous-rules" : "block"
        return (["trigger": trigger, "action": ["type": action]], isException)
    }

    private func urlFilter(_ raw: String) -> String? {
        guard raw.count > 2, !raw.hasPrefix("/") else { return nil }
        guard raw.hasPrefix("||") else {
            let anchored = raw.hasPrefix("|")
            return pattern(anchored ? String(raw.dropFirst()) : raw).map { (anchored ? "^" : "") + $0 }
        }
        let rest = String(raw.dropFirst(2))
        let host = rest.hasSuffix("^") ? String(rest.dropLast()) : rest
        if !host.isEmpty, !host.contains(where: { "/*^|".contains($0) }) {
            return MediaRuleExceptions.hostFilter(host.lowercased())
        }
        // `||` anchors to a host boundary, not to the start of the URL.
        return pattern(rest).map { "^https?://([^/]*\\.)?" + $0 }
    }

    /// WebKit already searches the whole URL, so an unanchored filter needs no
    /// `.*` on either side — padding it only makes the automaton bigger.
    private func pattern(_ raw: String) -> String? {
        let anchoredEnd = raw.hasSuffix("|")
        let trimmed = raw.trimmingCharacters(in: CharacterSet(charactersIn: "|*"))
        guard trimmed.count > 2 else { return nil }
        var value = NSRegularExpression.escapedPattern(for: trimmed)
        value = value.replacingOccurrences(of: "\\*", with: ".*")
        value = value.replacingOccurrences(of: "\\^", with: "[^A-Za-z0-9_.%-]")
        let filter = value + (anchoredEnd ? "$" : "")
        guard filter.count < 1_000,
              (try? NSRegularExpression(pattern: filter)) != nil else { return nil }
        return filter
    }
}
