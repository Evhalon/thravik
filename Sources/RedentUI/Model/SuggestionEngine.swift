import Foundation
import RedentKit

/// Turns what the user has typed into the address bar's dropdown.
///
/// Composes the two stores rather than living in either, because the ranking
/// question — "is this bookmark worth more than that visit?" — belongs to
/// neither of them alone.
public struct SuggestionEngine: Sendable {
    private let history: any HistoryStoring
    private let bookmarks: any BookmarkStoring

    public init(history: any HistoryStoring, bookmarks: any BookmarkStoring) {
        self.history = history
        self.bookmarks = bookmarks
    }

    public func suggestions(
        for query: String,
        engine: SearchEngine,
        limit: Int = 8
    ) async -> [AddressSuggestion] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        var rows: [AddressSuggestion] = []
        var seen = Set<String>()

        if let direct = directURL(for: trimmed) {
            rows.append(direct)
            seen.insert(key(direct.url))
        }

        // Saved pages rank above visited ones: bookmarking is an explicit
        // signal, a visit is often an accident.
        for bookmark in await bookmarks.search(trimmed, limit: limit) {
            guard seen.insert(key(bookmark.url)).inserted else { continue }
            rows.append(AddressSuggestion(
                kind: .bookmark,
                title: bookmark.displayTitle,
                subtitle: subtitle(for: bookmark.url),
                url: bookmark.url,
                faviconData: bookmark.faviconData,
                score: 1_000
            ))
        }

        let roomForHistory = max(0, limit - rows.count - 1)
        for entry in await history.search(trimmed, limit: roomForHistory) {
            guard rows.count < limit - 1, seen.insert(key(entry.url)).inserted else { continue }
            rows.append(AddressSuggestion(
                kind: .history,
                title: entry.displayTitle,
                subtitle: subtitle(for: entry.url),
                url: entry.url,
                score: entry.score()
            ))
        }

        // Exactly one search row, always last, so pressing return on an
        // unmatched query does the same thing every time.
        if let searchURL = engine.searchURL(for: trimmed) {
            rows.append(AddressSuggestion(
                kind: .search,
                title: trimmed,
                subtitle: "Search with \(engine.label)",
                url: searchURL,
                score: 0
            ))
        }
        return Array(rows.prefix(limit))
    }

    private func directURL(for query: String) -> AddressSuggestion? {
        guard let url = AddressResolver.resolve(query, using: .duckduckgo),
              let origin = Origin(url: url),
              !url.absoluteString.contains("duckduckgo.com/?q=")
        else { return nil }
        return AddressSuggestion(
            kind: .directURL,
            title: origin.displayHost,
            subtitle: "Open directly",
            url: url,
            score: 10_000
        )
    }

    private func subtitle(for url: URL) -> String {
        let host = Origin(url: url)?.displayHost ?? url.absoluteString
        let path = url.path()
        return path.isEmpty || path == "/" ? host : host + path
    }

    /// Trailing slashes are the same page; query strings never reach here.
    private func key(_ url: URL) -> String {
        var text = url.absoluteString
        if text.hasSuffix("/") { text.removeLast() }
        return text.lowercased()
    }
}
