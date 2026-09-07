import Foundation
import RedentKit

/// Frecency ranking on top of a bounded SQL candidate set — SQL narrows the
/// field with `LIKE`, Swift decides the order with `HistoryEntry.score`.
enum HistoryRanking {
    /// Strongest match first: host prefix beats host substring beats title
    /// prefix beats title substring beats a bare path/url substring.
    static func matchQuality(of entry: HistoryEntry, matching query: String) -> Double {
        let needle = query.lowercased()
        let host = entry.origin?.host ?? ""
        let title = entry.title.lowercased()

        if host.hasPrefix(needle) { return 100 }
        if host.contains(needle) { return 50 }
        if title.hasPrefix(needle) { return 25 }
        if title.contains(needle) { return 12 }
        if entry.url.path.lowercased().contains(needle) { return 5 }
        return 1
    }

    static func rank(_ entries: [HistoryEntry], matching query: String, at now: Date, limit: Int) -> [HistoryEntry] {
        entries
            .map { ($0, $0.score(at: now) * matchQuality(of: $0, matching: query)) }
            .sorted {
                if $0.1 != $1.1 { return $0.1 > $1.1 }
                if $0.0.lastVisit != $1.0.lastVisit { return $0.0.lastVisit > $1.0.lastVisit }
                return $0.0.url.absoluteString < $1.0.url.absoluteString
            }
            .prefix(limit)
            .map(\.0)
    }

    /// Collapses to the highest-scoring page per host, so a new-tab grid
    /// shows distinct sites rather than several pages of the same one.
    static func bestPerHost(_ entries: [HistoryEntry], at now: Date, limit: Int) -> [HistoryEntry] {
        var bestByHost: [String: HistoryEntry] = [:]
        for entry in entries {
            let host = entry.origin?.host ?? entry.url.absoluteString
            if let existing = bestByHost[host], existing.score(at: now) >= entry.score(at: now) {
                continue
            }
            bestByHost[host] = entry
        }
        return bestByHost.values
            .sorted { $0.score(at: now) > $1.score(at: now) }
            .prefix(limit)
            .map { $0 }
    }
}
