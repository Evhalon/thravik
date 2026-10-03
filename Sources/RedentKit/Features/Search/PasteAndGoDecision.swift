import Foundation

public enum PasteAndGoDecision {
    public enum Action: Hashable, Sendable {
        case go(URL)
        case search(URL)

        public var url: URL {
            switch self {
            case .go(let url), .search(let url): url
            }
        }

        public var menuTitle: String {
            switch self {
            case .go: "Paste and Go"
            case .search: "Paste and Search"
            }
        }
    }

    public static func action(for clipboard: String, using engine: SearchEngine) -> Action? {
        action(for: clipboard, using: SearchRouting(engine: engine))
    }

    public static func action(for clipboard: String, using routing: SearchRouting) -> Action? {
        let text = firstUsefulLine(clipboard)
        guard !text.isEmpty else { return nil }
        guard let url = AddressResolver.resolve(text, using: routing) else { return nil }
        if SearchKeywordResolver.match(in: text, engines: routing.customEngines) != nil {
            return .search(url)
        }
        if url == routing.searchURL(for: text) { return .search(url) }
        return .go(url)
    }

    /// Multi-line paste keeps the first non-empty line. Browsers treat a
    /// clipboard of several lines as one address or one query, not a list.
    public static func firstUsefulLine(_ clipboard: String) -> String {
        for line in clipboard.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty { return trimmed }
        }
        return ""
    }
}
