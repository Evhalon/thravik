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

    /// - Parameter allowsCompletion: false while the user is deleting, so
    ///   backspace removes the completion instead of fighting it.
    public func suggestions(
        for query: String,
        context: SuggestionContext,
        allowsCompletion: Bool = true,
        limit: Int = 8
    ) async -> SuggestionResult {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return .empty }

        // Both stores are asked at once; each is its own actor.
        async let saved = bookmarks.search(text, in: context.spaceID, limit: limit)
        async let visited = history.search(text, in: context.spaceID, limit: limit)
        let (bookmarkHits, historyHits) = await (saved, visited)

        let known = bookmarkHits.map { KnownPage(url: $0.url, title: $0.displayTitle) }
            + historyHits.map { KnownPage(url: $0.url, title: $0.displayTitle) }
        let completion = allowsCompletion
            ? InlineCompletionFinder.completion(for: text, candidates: known.map(\.url))
            : nil

        var list = SuggestionRows(query: text, searchEngine: context.searchEngine, limit: limit)
        list.lead(with: completion, known: known)
        list.add(openTabs: context.openTabs)
        // Saved pages rank above visited ones: bookmarking is an explicit
        // signal, a visit is often an accident.
        list.add(bookmarkHits.map {
            AddressSuggestion(kind: .bookmark, title: $0.displayTitle,
                              subtitle: SuggestionRows.subtitle(for: $0.url), url: $0.url, faviconData: $0.faviconData)
        })
        list.add(historyHits.map {
            AddressSuggestion(kind: .history, title: $0.displayTitle,
                              subtitle: SuggestionRows.subtitle(for: $0.url), url: $0.url)
        })
        return SuggestionResult(rows: list.finish(), completion: completion)
    }
}
