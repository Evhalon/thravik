import Foundation

struct AdblockFilterParser: Sendable {
    func encodedRules(from text: String) -> String? {
        var blocking = [[String: Any]]()
        var exceptions = [[String: Any]]()
        var selectors = [String]()
        for rawLine in text.split(whereSeparator: \.isNewline) {
            parse(String(rawLine), blocking: &blocking, exceptions: &exceptions, selectors: &selectors)
        }
        blocking.append(contentsOf: cosmeticRules(selectors))
        blocking.append(contentsOf: exceptions)
        guard !blocking.isEmpty, JSONSerialization.isValidJSONObject(blocking),
              let data = try? JSONSerialization.data(withJSONObject: blocking)
        else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func parse(
        _ line: String,
        blocking: inout [[String: Any]],
        exceptions: inout [[String: Any]],
        selectors: inout [String]
    ) {
        guard !line.isEmpty, !line.hasPrefix("!"), !line.hasPrefix("[") else { return }
        if let selector = cosmeticSelector(line) {
            selectors.append(selector)
            return
        }
        guard !line.contains("##"), !line.contains("#@#"), !line.contains("#$#") else { return }
        let allowed = line.hasPrefix("@@")
        let body = allowed ? String(line.dropFirst(2)) : line
        let parts = body.split(separator: "$", maxSplits: 1).map(String.init)
        let options = parts.count == 2 ? parts[1] : nil
        guard let filter = urlFilter(parts[0]), !unsupported(options) else { return }
        guard options?.contains("~third-party") != true,
              options?.contains("first-party") != true else { return }
        let trigger: [String: Any] = [
            "url-filter": filter,
            "load-type": ["third-party"]
        ]
        let type = allowed ? "ignore-previous-rules" : "block"
        let rule: [String: Any] = ["trigger": trigger, "action": ["type": type]]
        if allowed { exceptions.append(rule) } else { blocking.append(rule) }
    }

    private func cosmeticSelector(_ line: String) -> String? {
        guard line.hasPrefix("##") else { return nil }
        let selector = String(line.dropFirst(2))
        let unsupported = ["+js(", ":-abp-", ":style(", ":remove(", "##"]
        guard !selector.isEmpty, selector.count < 500,
              !unsupported.contains(where: selector.contains)
        else { return nil }
        return selector
    }

    private func unsupported(_ options: String?) -> Bool {
        guard let options else { return false }
        return options.contains("document") || options.contains("domain=") || options.contains("redirect=")
    }

    private func urlFilter(_ raw: String) -> String? {
        guard raw.count > 2, !raw.hasPrefix("/") else { return nil }
        if raw.hasPrefix("||") {
            let value = String(raw.dropFirst(2)).replacingOccurrences(of: "^", with: "")
            let host = value.split(separator: "/", maxSplits: 1).first.map(String.init) ?? value
            guard !host.contains("*"), host == value else { return wildcard(raw) }
            let escaped = NSRegularExpression.escapedPattern(for: host)
            return "^https?://([^/]*\\.)?\(escaped)[:/]"
        }
        return wildcard(raw)
    }

    private func wildcard(_ raw: String) -> String? {
        let anchoredStart = raw.hasPrefix("|")
        let anchoredEnd = raw.hasSuffix("|")
        let trimmed = raw.trimmingCharacters(in: CharacterSet(charactersIn: "|"))
        guard !trimmed.isEmpty else { return nil }
        var value = NSRegularExpression.escapedPattern(for: trimmed)
        value = value.replacingOccurrences(of: "\\*", with: ".*")
        value = value.replacingOccurrences(of: "\\^", with: "[^A-Za-z0-9_.%-]")
        let filter = (anchoredStart ? "^" : ".*") + value + (anchoredEnd ? "$" : ".*")
        guard filter.count < 1_000,
              (try? NSRegularExpression(pattern: filter)) != nil else { return nil }
        return filter
    }

    private func cosmeticRules(_ selectors: [String]) -> [[String: Any]] {
        stride(from: 0, to: selectors.count, by: 100).map { start in
            let end = min(start + 100, selectors.count)
            return [
                "trigger": ["url-filter": ".*"],
                "action": ["type": "css-display-none", "selector": selectors[start..<end].joined(separator: ",")]
            ]
        }
    }
}
