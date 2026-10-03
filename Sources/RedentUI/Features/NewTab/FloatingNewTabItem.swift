import Foundation
import RedentKit

struct FloatingNewTabItem: Identifiable {
    enum Target {
        case tab(UUID)
        case page(URL)
        case blank
        case suggestion(AddressSuggestion)
    }

    enum Section: String {
        case continueBrowsing = "Continue browsing"
        case tabs = "Tabs"
        case bookmarks = "Bookmarks"
        case recent = "Recent"
        case newTab = "New tab"
        case search = "Results"
    }

    let id: String
    let title: String
    let detail: String
    let symbol: String
    let faviconData: Data?
    let url: URL?
    let section: Section
    let target: Target

    static func suggestion(_ row: AddressSuggestion) -> Self {
        Self(id: row.id, title: row.title, detail: row.subtitle,
             symbol: row.kind.symbol, faviconData: row.faviconData, url: row.url,
             section: .search, target: .suggestion(row))
    }

    static func preview(_ text: String, routing: SearchRouting) -> Self? {
        guard let action = PasteAndGoDecision.action(for: text, using: routing) else { return nil }
        let isSearch = if case .search = action { true } else { false }
        let match = SearchKeywordResolver.match(in: text, engines: routing.customEngines)
        return Self(id: "preview", title: isSearch ? "Search for \(match?.query ?? text)" : "Open \(text)",
            detail: isSearch ? (match?.engine.name ?? routing.label) : action.url.host() ?? action.url.absoluteString,
            symbol: isSearch ? "magnifyingglass" : "arrow.up.right",
            faviconData: nil, url: nil, section: .search, target: .page(action.url))
    }
}
