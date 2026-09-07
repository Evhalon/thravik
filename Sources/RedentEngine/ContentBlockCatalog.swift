import Foundation

/// Bundled EasyList/EasyPrivacy-style catalog: dedicated ad networks, known
/// trackers, leftover URL paths, and cosmetic hide selectors.
struct ContentBlockCatalog: Decodable, Equatable, Sendable {
    var adDomains: [String]
    var trackerDomains: [String]
    var pathFilters: [String]
    var hideSelectors: [String]

    static func load(from bundle: Bundle = .module) -> ContentBlockCatalog? {
        guard let url = bundle.url(forResource: "adblock-catalog", withExtension: "json"),
              let data = try? Data(contentsOf: url)
        else { return nil }
        return try? JSONDecoder().decode(ContentBlockCatalog.self, from: data)
    }
}
