import Foundation
import RedentKit

enum CommandSearch {
    struct Source {
        let descriptors: [CommandDescriptor]
        let history: any HistoryStoring
        let bookmarks: any BookmarkStoring
        let searchEngine: SearchEngine
    }

    static func results(
        query: String,
        context: CommandBarContext,
        source: Source,
        limit: Int
    ) async -> [CommandBarResult] {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return Array(CommandHome.rows(context: context, descriptors: source.descriptors).prefix(limit)) }
        // A plain command reads before any page does, and a reading of the
        // whole sentence before a command that only shares its first words.
        let intents = CommandIntentParser.intents(for: text, in: context, searchEngine: source.searchEngine)
        let intentActions = Set(intents.compactMap(\.action))
        let entities = CommandEntityRows.rows(matching: text, in: context)
        var rows = commandRows(source.descriptors, context: context, query: text)
            .filter { $0.action.map { !intentActions.contains($0) } ?? true }
        rows += entities

        let spaceID = currentSpaceID(context)
        async let saved = source.bookmarks.search(text, in: spaceID, limit: limit)
        async let visited = source.history.search(text, in: spaceID, limit: limit)
        let (bookmarks, history) = await (saved, visited)
        // An open tab already represents that page: it owns the row for that URL.
        let shownTabs = Set(entities.filter { $0.source == .tab }.map(\.id))
        var seen = Set(context.tabs.filter { shownTabs.contains("tab:\($0.id)") }.compactMap { $0.url.map(normalizedURL) })
        rows += bookmarks.compactMap { bookmark in
            guard seen.insert(normalizedURL(bookmark.url)).inserted else { return nil }
            return CommandBarResult(id: "bookmark:\(bookmark.id)", title: bookmark.displayTitle,
                                    subtitle: bookmark.folderLabel, source: .bookmark,
                                    action: .navigate(bookmark.url))
        }
        rows += history.compactMap { entry in
            guard seen.insert(normalizedURL(entry.url)).inserted else { return nil }
            return CommandBarResult(id: "history:\(entry.id)", title: entry.displayTitle,
                                    subtitle: entry.url.absoluteString, source: .history,
                                    action: .navigate(entry.url))
        }
        let ordered = CommandRanking.order(rows, direct: directRow(for: text, searchEngine: source.searchEngine),
                                           search: searchRow(for: text, searchEngine: source.searchEngine), query: text)
        return Array((intents + ordered).prefix(limit))
    }

    /// Bookmarks and the visit leaderboard are per Space; the bar reads the one you are in.
    private static func currentSpaceID(_ context: CommandBarContext) -> UUID? {
        context.spaces.first { $0.isCurrent }?.id
    }

    private static func commandRows(_ descriptors: [CommandDescriptor], context: CommandBarContext, query: String) -> [CommandBarResult] {
        descriptors.filter { $0.matches(query) }.compactMap { $0.row(in: context, query: query) }
    }

    private static func directRow(for query: String, searchEngine: SearchEngine) -> CommandBarResult? {
        directURL(for: query, searchEngine: searchEngine).map {
            CommandBarResult(id: "direct:\($0.absoluteString)", title: $0.absoluteString,
                             subtitle: "Open address", source: .directURL, action: .navigate($0))
        }
    }

    private static func searchRow(for query: String, searchEngine: SearchEngine) -> CommandBarResult? {
        searchEngine.searchURL(for: query).map {
            CommandBarResult(id: "search:\(query)", title: query,
                             subtitle: "Search \(searchEngine.label)", source: .search, action: .navigate($0))
        }
    }

    private static func directURL(for query: String, searchEngine: SearchEngine) -> URL? {
        guard let url = AddressResolver.resolve(query, using: searchEngine),
              url != searchEngine.searchURL(for: query) else { return nil }
        return url
    }

    private static func normalizedURL(_ url: URL) -> String {
        var value = url.absoluteString.lowercased()
        if value.hasSuffix("/") { value.removeLast() }
        return value
    }
}
