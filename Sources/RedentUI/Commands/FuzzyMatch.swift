import Foundation

/// How well a typed fragment fits a piece of text, without the user having to
/// spell it out: "git" finds "Pull request #182 — OnePanel — GitHub", and
/// "gthb" still finds it by the letters' order.
///
/// Scores are small integers so ranking stays explainable: 5 exact, 4 prefix,
/// 3 start of a word, 2 anywhere inside, 1 letters in order, 0 no match.
enum FuzzyMatch {
    /// Shorter fragments match far too much by letter order alone.
    private static let minimumSubsequenceLength = 3

    static func score(_ needle: String, in text: String) -> Int {
        let needle = needle.lowercased()
        let text = text.lowercased()
        guard !needle.isEmpty, !text.isEmpty else { return 0 }
        if text == needle { return 5 }
        if text.hasPrefix(needle) { return 4 }
        if words(of: text).contains(where: { $0.hasPrefix(needle) }) { return 3 }
        if text.contains(needle) { return 2 }
        guard needle.count >= minimumSubsequenceLength, isSubsequence(needle, of: text) else { return 0 }
        return 1
    }

    /// The best score each term earns anywhere in `fields`, and the weakest of
    /// those: every word typed has to land somewhere.
    static func score(query: String, fields: [String?]) -> Int {
        let terms = query.lowercased().split(whereSeparator: \.isWhitespace).map(String.init)
        let present = fields.compactMap { $0 }.filter { !$0.isEmpty }
        guard !terms.isEmpty else { return 0 }
        return terms.map { term in present.map { score(term, in: $0) }.max() ?? 0 }.min() ?? 0
    }

    /// `fields` may match loosely; `exact` fields — a whole URL, say — only by
    /// substring, since letters in order are found in any long enough address.
    static func matches(_ query: String, fields: [String?], exact: [String?] = []) -> Bool {
        let terms = query.lowercased().split(whereSeparator: \.isWhitespace).map(String.init)
        guard !terms.isEmpty else { return true }
        let loose = fields.compactMap { $0 }
        let strict = exact.compactMap { $0?.lowercased() }
        return terms.allSatisfy { term in
            loose.contains { score(term, in: $0) > 0 } || strict.contains { $0.contains(term) }
        }
    }

    private static func words(of text: String) -> [Substring] {
        text.split { !$0.isLetter && !$0.isNumber }
    }

    private static func isSubsequence(_ needle: String, of text: String) -> Bool {
        var remaining = needle[...]
        for character in text where character == remaining.first {
            remaining = remaining.dropFirst()
            if remaining.isEmpty { return true }
        }
        return remaining.isEmpty
    }
}
