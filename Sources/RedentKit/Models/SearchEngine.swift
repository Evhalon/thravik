import Foundation

public enum SearchEngine: String, Codable, Sendable, CaseIterable, Identifiable {
    case duckduckgo, google, bing, brave, ecosia

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .duckduckgo: "DuckDuckGo"
        case .google: "Google"
        case .bing: "Bing"
        case .brave: "Brave"
        case .ecosia: "Ecosia"
        }
    }

    private var queryTemplate: String {
        switch self {
        case .duckduckgo: "https://duckduckgo.com/?q="
        case .google: "https://www.google.com/search?q="
        case .bing: "https://www.bing.com/search?q="
        case .brave: "https://search.brave.com/search?q="
        case .ecosia: "https://www.ecosia.org/search?q="
        }
    }

    public func searchURL(for query: String) -> URL? {
        let allowed = CharacterSet.urlQueryAllowed.subtracting(CharacterSet(charactersIn: "+&=?#"))
        guard let escaped = query.addingPercentEncoding(withAllowedCharacters: allowed) else { return nil }
        return URL(string: queryTemplate + escaped)
    }
}
