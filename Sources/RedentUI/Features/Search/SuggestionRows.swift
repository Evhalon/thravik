import Foundation
import RedentKit

/// A page a store already knows, reduced to what ranking the lead row needs.
struct KnownPage {
    let url: URL
    let title: String
}

/// Assembles the dropdown in a fixed shape the user can learn once:
/// what return does, then open tabs, then saved and visited pages, then —
/// unless it already leads — exactly one "search the web" row.
struct SuggestionRows {
    private let query: String
    private let searchEngine: SearchEngine
    private let limit: Int
    private var rows: [AddressSuggestion] = []
    private var seen = Set<String>()
    private var searchLeads = false

    init(query: String, searchEngine: SearchEngine, limit: Int) {
        self.query = query
        self.searchEngine = searchEngine
        self.limit = limit
    }

    /// The lead row mirrors what return does with the field's text, so the
    /// highlighted row and the keypress can never disagree.
    mutating func lead(with completion: InlineCompletion?, known: [KnownPage]) {
        if let completion {
            let host = completion.url.host()
            let title = known.first { $0.url.host() == host }?.title
            append(AddressSuggestion(kind: .directURL, title: completion.text,
                                     subtitle: title ?? "Open site", url: completion.url))
            return
        }
        if let direct = directURL() {
            append(AddressSuggestion(kind: .directURL, title: query, subtitle: "Open address", url: direct))
            return
        }
        searchLeads = true
        if let search = searchRow() { rows.append(search) }
    }

    /// An open tab owns its URL: a history row for the same page would only
    /// offer to load it a second time.
    mutating func add(openTabs: [OpenTabCandidate]) {
        let terms = query.lowercased().split(whereSeparator: \.isWhitespace)
        let matching = openTabs.filter { tab in
            let haystack = "\(tab.title) \(tab.url.host() ?? "")".lowercased()
            return terms.allSatisfy { haystack.contains($0) }
        }
        for tab in matching.prefix(3) {
            seen.insert(Self.key(tab.url))
            rows.append(.openTab(tab.id, title: tab.title, url: tab.url, faviconData: tab.faviconData))
        }
    }

    mutating func add(_ candidates: [AddressSuggestion]) {
        candidates.forEach { append($0) }
    }

    func finish() -> [AddressSuggestion] {
        guard !searchLeads, let search = searchRow() else { return Array(rows.prefix(limit)) }
        return Array(rows.prefix(limit - 1)) + [search]
    }

    static func subtitle(for url: URL) -> String {
        let host = Origin(url: url)?.displayHost ?? url.absoluteString
        let path = url.path()
        return path.isEmpty || path == "/" ? host : host + path
    }

    private mutating func append(_ row: AddressSuggestion) {
        guard seen.insert(Self.key(row.url)).inserted else { return }
        rows.append(row)
    }

    private func directURL() -> URL? {
        guard let url = AddressResolver.resolve(query, using: searchEngine),
              url != searchEngine.searchURL(for: query)
        else { return nil }
        return url
    }

    private func searchRow() -> AddressSuggestion? {
        searchEngine.searchURL(for: query).map {
            AddressSuggestion(kind: .search, title: query, subtitle: "Search \(searchEngine.label)", url: $0)
        }
    }

    /// Trailing slashes are the same page; query strings never reach here.
    private static func key(_ url: URL) -> String {
        var text = url.absoluteString
        if text.hasSuffix("/") { text.removeLast() }
        return text.lowercased()
    }
}
