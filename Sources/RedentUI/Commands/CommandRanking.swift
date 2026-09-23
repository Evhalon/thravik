import Foundation

/// Orders Command Bar rows by how well they match, not by where they came
/// from. Return opens the first row, so the first row has to be the best
/// guess: "new tab" runs New Tab, "git" switches to the open GitHub tab, and
/// "weather in rome" — which matches nothing well — searches the web.
enum CommandRanking {
    /// A match at least this good means the user typed toward a known thing.
    private static let strongMatch = 3

    static func order(
        _ rows: [CommandBarResult], direct: CommandBarResult?, search: CommandBarResult?, query: String
    ) -> [CommandBarResult] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let scored = rows.enumerated().map { index, row in
            (row: row, score: score(row, needle: needle), index: index)
        }
        let ranked = scored.sorted { lhs, rhs in
            if lhs.score != rhs.score { return lhs.score > rhs.score }
            if sourceRank(lhs.row.source) != sourceRank(rhs.row.source) {
                return sourceRank(lhs.row.source) < sourceRank(rhs.row.source)
            }
            return lhs.index < rhs.index
        }
        let searchLeads = (ranked.first?.score ?? 0) < strongMatch
        var result: [CommandBarResult] = direct.map { [$0] } ?? []
        if searchLeads, let search { result.append(search) }
        result += ranked.map(\.row)
        if !searchLeads, let search { result.append(search) }
        return result
    }

    static func score(_ row: CommandBarResult, needle: String) -> Int {
        guard !needle.isEmpty else { return 0 }
        let title = row.title.lowercased()
        if title == needle { return 5 }
        if title.hasPrefix(needle) || host(of: row).hasPrefix(needle) { return 4 }
        let words = title.split { !$0.isLetter && !$0.isNumber }
        if words.contains(where: { $0.hasPrefix(needle) }) { return 3 }
        if title.contains(needle) { return 2 }
        return 1
    }

    /// Among equal matches, what is already open beats what can be done,
    /// which beats what was once visited.
    private static func sourceRank(_ source: CommandResultSource) -> Int {
        switch source {
        case .tab: 0
        case .command: 1
        case .space: 2
        case .bookmark: 3
        case .history: 4
        case .directURL, .search: 5
        }
    }

    /// Only tabs and visits carry a URL in their subtitle; a command's
    /// "Command" must not read as a host every query starts.
    private static func host(of row: CommandBarResult) -> String {
        guard row.source == .tab || row.source == .history else { return "" }
        let text = row.subtitle.lowercased()
        let bare = text.split(separator: "://", maxSplits: 1).last.map(String.init) ?? text
        return bare.hasPrefix("www.") ? String(bare.dropFirst(4)) : bare
    }
}
