import Foundation

/// The `$…` part of a network filter, reduced to what a WebKit trigger can say.
///
/// A modifier WebKit cannot express makes the whole filter unusable. Dropping
/// it instead silently widens the filter: `$redirect-rule=`, `$csp=` or
/// `$removeparam=` read as a plain block is how whole video players went dark.
struct AdblockFilterOptions {
    /// Every type a block may name by default. `media` stays out: the bytes of
    /// a player are never the ad, and `popup` is decided before a tab exists.
    static let defaultBlockedTypes = [
        "document", "image", "style-sheet", "script", "font", "raw",
        "svg-document", "ping", "fetch", "websocket", "other",
    ]

    private static let types: [String: [String]] = [
        "script": ["script"], "image": ["image"], "stylesheet": ["style-sheet"],
        "css": ["style-sheet"], "font": ["font"], "xmlhttprequest": ["fetch", "raw"],
        "xhr": ["fetch", "raw"], "subdocument": ["document"], "frame": ["document"],
        "ping": ["ping"], "beacon": ["ping"], "websocket": ["websocket"],
        "other": ["other"], "object": ["other"], "media": ["media"],
    ]

    /// Modifiers that only restate what every converted rule already does.
    private static let neutral: Set<String> = ["third-party", "3p", "~first-party", "~1p", "important", "match-case"]

    private(set) var resourceTypes: [String]?
    private(set) var ifDomains: [String] = []
    private(set) var unlessDomains: [String] = []

    /// - Returns: `nil` when the filter cannot be converted faithfully.
    init?(_ raw: String?, isException: Bool) {
        var included = Set<String>()
        var excluded = Set<String>()
        for option in raw?.split(separator: ",").map(String.init) ?? [] {
            if Self.neutral.contains(option) { continue }
            if let domains = Self.domainList(option) {
                guard parseDomains(domains) else { return nil }
            } else if let mapped = Self.types[option] {
                included.formUnion(mapped)
            } else if option.hasPrefix("~"), let mapped = Self.types[String(option.dropFirst())] {
                excluded.formUnion(mapped)
            } else {
                return nil
            }
        }
        guard ifDomains.isEmpty || unlessDomains.isEmpty else { return nil }
        resourceTypes = Self.resolveTypes(included, excluded, isException: isException)
        guard resourceTypes?.isEmpty != true else { return nil }
    }

    var triggerFields: [String: Any] {
        var fields: [String: Any] = [:]
        if let resourceTypes { fields["resource-type"] = resourceTypes }
        if !ifDomains.isEmpty { fields["if-domain"] = ifDomains }
        if !unlessDomains.isEmpty { fields["unless-domain"] = unlessDomains }
        return fields
    }

    private static func resolveTypes(_ included: Set<String>, _ excluded: Set<String>, isException: Bool) -> [String]? {
        if included.isEmpty, excluded.isEmpty {
            return isException ? nil : defaultBlockedTypes
        }
        let base = included.isEmpty ? Set(defaultBlockedTypes) : included
        let allowed = isException ? base : base.subtracting(["media"])
        return allowed.subtracting(excluded).sorted()
    }

    private static func domainList(_ option: String) -> Substring? {
        for key in ["domain=", "from="] where option.hasPrefix(key) {
            return option.dropFirst(key.count)
        }
        return nil
    }

    /// WebKit wants lowercase hosts, `*` for "and its subdomains", and has no
    /// notion of uBlock's `example.*` entity form.
    private mutating func parseDomains(_ list: Substring) -> Bool {
        for entry in list.split(separator: "|") {
            let negated = entry.hasPrefix("~")
            let host = (negated ? entry.dropFirst() : entry).lowercased()
            guard !host.isEmpty, host.allSatisfy(Self.isHostCharacter) else { return false }
            if negated { unlessDomains.append("*" + host) } else { ifDomains.append("*" + host) }
        }
        return true
    }

    private static func isHostCharacter(_ character: Character) -> Bool {
        character.isASCII && (character.isLetter || character.isNumber || character == "." || character == "-")
    }
}
