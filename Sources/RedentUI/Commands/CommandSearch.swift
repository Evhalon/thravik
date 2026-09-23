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
        let openTabs = context.tabs.filter {
            matches(text, values: [$0.title, $0.url?.absoluteString, $0.spaceName])
        }
        var rows = commandRows(source.descriptors, context: context, query: text)
        rows.append(contentsOf: tabRows(openTabs))
        rows.append(contentsOf: spaceRows(context.spaces, query: text))
        guard !text.isEmpty else { return Array(rows.prefix(limit)) }

        let spaceID = currentSpaceID(context)
        async let saved = source.bookmarks.search(text, in: spaceID, limit: limit)
        async let visited = source.history.search(text, in: spaceID, limit: limit)
        let (bookmarks, history) = await (saved, visited)
        // An open tab already represents that page: it owns the row for that URL.
        var seen = Set(openTabs.compactMap { $0.url.map(normalizedURL) })
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
        return Array(ordered.prefix(limit))
    }

    /// Bookmarks and the visit leaderboard are per Space; the bar reads the one you are in.
    private static func currentSpaceID(_ context: CommandBarContext) -> UUID? {
        context.spaces.first { $0.isCurrent }?.id
    }

    private static func commandRows(_ descriptors: [CommandDescriptor], context: CommandBarContext, query: String) -> [CommandBarResult] {
        descriptors.filter { $0.matches(query) }.compactMap { descriptor in
            guard let action = descriptor.action(in: context, query: query) else { return nil }
            return CommandBarResult(id: "command:\(descriptor.id)", title: descriptor.title,
                                    subtitle: "Command", source: .command, action: action)
        }
    }

    private static func tabRows(_ tabs: [CommandTabContext]) -> [CommandBarResult] {
        tabs.map { tab in
            let subtitle = [tab.url?.absoluteString, tab.spaceName].compactMap { $0 }.joined(separator: " · ")
            return CommandBarResult(id: "tab:\(tab.id)", title: tab.title.isEmpty ? "Untitled Tab" : tab.title,
                                    subtitle: subtitle, source: .tab, action: .focusTab(tab.id))
        }
    }

    private static func spaceRows(_ spaces: [CommandSpaceContext], query: String) -> [CommandBarResult] {
        spaces.filter { matches(query, values: [$0.name]) }.map { space in
            CommandBarResult(id: "space:\(space.id)", title: space.name,
                             subtitle: "Space · \(space.tabIDs.count) tabs", source: .space,
                             action: .focusSpace(space.id))
        }
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

    private static func matches(_ query: String, values: [String?]) -> Bool {
        let terms = query.lowercased().split(whereSeparator: { $0 == " " })
        guard !terms.isEmpty else { return true }
        let haystack = values.compactMap { $0 }.joined(separator: " ").lowercased()
        return terms.allSatisfy { haystack.contains($0) }
    }

    private static func normalizedURL(_ url: URL) -> String {
        var value = url.absoluteString.lowercased()
        if value.hasSuffix("/") { value.removeLast() }
        return value
    }
}
