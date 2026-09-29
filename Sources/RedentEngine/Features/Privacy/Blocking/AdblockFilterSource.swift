import Foundation

struct AdblockFilterSource: Sendable {
    let id: String
    let url: URL

    static let braveDefaults: [AdblockFilterSource] = [
        source("easylist", "https://easylist.to/easylist/easylist.txt"),
        source("easyprivacy", "https://easylist.to/easylist/easyprivacy.txt"),
        source("ublock", "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/filters.txt"),
        source("ublock-privacy", "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/privacy.txt"),
        source("brave", "https://raw.githubusercontent.com/brave/adblock-lists/master/brave-lists/brave-specific.txt")
    ].compactMap { $0 }

    private static func source(_ id: String, _ address: String) -> AdblockFilterSource? {
        guard let url = URL(string: address) else { return nil }
        return AdblockFilterSource(id: id, url: url)
    }
}
