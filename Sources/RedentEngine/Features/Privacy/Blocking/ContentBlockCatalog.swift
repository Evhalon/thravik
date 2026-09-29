import Foundation

/// Bundled EasyList/EasyPrivacy-style catalog: dedicated ad networks, known
/// trackers, leftover URL paths, and cosmetic hide selectors.
struct ContentBlockCatalog: Decodable, Equatable, Sendable {
    var adDomains: [String]
    var trackerDomains: [String]
    var pathFilters: [String]
    var hideSelectors: [String]

    /// `bundle` is optional because the resource bundle can be missing from a
    /// badly assembled `.app`; that degrades blocking, it does not crash.
    static func load(from bundle: Bundle? = EngineResources.bundle) -> ContentBlockCatalog? {
        guard let url = bundle?.url(forResource: "adblock-catalog", withExtension: "json"),
              let data = try? Data(contentsOf: url)
        else { return nil }
        return try? JSONDecoder().decode(ContentBlockCatalog.self, from: data)
    }

    func blocksPopup(_ url: URL, from topURL: URL?) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        if adDomains.contains(where: { host.matchesDomain($0) }) { return true }
        let topHost = topURL?.host?.lowercased()
        let isThirdParty = topHost.map { !host.matchesDomain($0) } ?? true
        if isThirdParty, trackerDomains.contains(where: { host.matchesDomain($0) }) { return true }
        let address = url.absoluteString.lowercased()
        return isThirdParty && pathFilters.contains { address.contains($0.lowercased()) }
    }
}

private extension String {
    func matchesDomain(_ domain: String) -> Bool {
        self == domain || hasSuffix(".\(domain)")
    }
}
