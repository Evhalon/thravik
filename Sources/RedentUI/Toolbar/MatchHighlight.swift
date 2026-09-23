import Foundation

/// Bolds the part of a result that matched the query, so the eye lands on
/// why each row is there instead of reading every title in full.
enum MatchHighlight {
    static func attributed(_ text: String, matching query: String) -> AttributedString {
        var result = AttributedString(text)
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty,
              let range = text.range(of: needle, options: [.caseInsensitive, .diacriticInsensitive]),
              let lower = AttributedString.Index(range.lowerBound, within: result),
              let upper = AttributedString.Index(range.upperBound, within: result)
        else { return result }
        result[lower..<upper].inlinePresentationIntent = .stronglyEmphasized
        return result
    }
}
