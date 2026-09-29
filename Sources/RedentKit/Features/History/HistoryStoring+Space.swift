import Foundation

public extension HistoryStoring {
    /// Address-bar matches led by the Space's own leaderboard: pages ranked by
    /// how often and how recently they were opened *in this Space*, then the
    /// rest of history to fill the list. A site you live in at work should be
    /// the first guess at work, even if it is a footnote everywhere else.
    func search(_ text: String, in spaceID: UUID?, limit: Int) async -> [HistoryEntry] {
        guard let spaceID, limit > 0 else { return await search(text, limit: limit) }
        async let local = query(HistoryQuery(
            text: text, scope: HistoryScope(spaceID: spaceID), limit: limit
        ))
        async let global = search(text, limit: limit)
        let (spaceRanked, everywhere) = await (local, global)
        var seen = Set<URL>()
        return Array((spaceRanked + everywhere).filter { seen.insert($0.url).inserted }.prefix(limit))
    }
}
