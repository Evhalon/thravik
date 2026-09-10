import Foundation

/// Pulls `link rel=icon` hrefs out of a homepage. Same origin only.
enum SiteIconHTML {
    static func iconURLs(in html: String, host: String) -> [URL] {
        let host = host.lowercased()
        guard let base = URL(string: "https://\(host)/") else { return [] }
        var scored: [(Int, URL)] = []
        var remainder = html[...]
        while let start = remainder.range(of: "<link", options: .caseInsensitive) {
            guard let end = remainder[start.lowerBound...].range(of: ">") else { break }
            let tag = String(remainder[start.lowerBound..<end.upperBound])
            remainder = remainder[end.upperBound...]
            if let hit = scoredURL(in: tag, host: host, base: base) { scored.append(hit) }
        }
        return scored.sorted { $0.0 > $1.0 }.map(\.1)
    }

    private static func scoredURL(in tag: String, host: String, base: URL) -> (Int, URL)? {
        let rel = attribute("rel", in: tag)?.lowercased() ?? ""
        guard rel.contains("icon") else { return nil }
        guard let href = attribute("href", in: tag),
              let url = URL(string: href, relativeTo: base)?.absoluteURL,
              isAllowed(url, host: host)
        else { return nil }
        return (score(rel: rel, href: href, sizes: attribute("sizes", in: tag), type: attribute("type", in: tag)), url)
    }

    private static func isAllowed(_ url: URL, host: String) -> Bool {
        guard url.scheme?.lowercased() == "https", let urlHost = url.host()?.lowercased() else { return false }
        return urlHost == host || urlHost == "www.\(host)" || host == "www.\(urlHost)"
    }

    private static func score(rel: String, href: String, sizes: String?, type: String?) -> Int {
        let kind = (type ?? "") + href
        var value = Int(sizes?.split(separator: "x").first ?? "0") ?? 0
        if kind.localizedCaseInsensitiveContains("png") { value += 10_000 }
        else if kind.localizedCaseInsensitiveContains("svg") { value += 5_000 }
        if rel.contains("apple-touch") { value += 50 }
        return value
    }

    private static func attribute(_ name: String, in tag: String) -> String? {
        guard let nameRange = tag.range(of: "\(name)=", options: .caseInsensitive) else { return nil }
        let after = tag[nameRange.upperBound...]
        guard let quote = after.first, quote == "\"" || quote == "'" else { return nil }
        let rest = after.dropFirst()
        guard let close = rest.firstIndex(of: quote) else { return nil }
        return String(rest[..<close])
    }
}
