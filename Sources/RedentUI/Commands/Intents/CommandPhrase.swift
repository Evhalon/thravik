import Foundation

/// A typed command, normalised for matching: lower case, single spaces, no
/// trailing punctuation. "  Close   YouTube tabs! " reads "close youtube tabs".
struct CommandPhrase: Equatable {
    let text: String
    /// The same words with the user's capitals, for arguments where case
    /// matters — a URL's path does.
    private let original: String

    init(_ raw: String) {
        original = raw
            .trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
        text = original.lowercased()
    }

    /// `fragment`, a piece of `text`, as the user actually typed it.
    func preservingCase(_ fragment: String) -> String {
        guard let range = text.range(of: fragment), text.count == original.count else { return fragment }
        let start = text.distance(from: text.startIndex, to: range.lowerBound)
        return String(original.dropFirst(start).prefix(fragment.count))
    }

    /// The words after the longest of `prefixes` the phrase opens with, or nil
    /// when it opens with none. A prefix must end on a word boundary: "moved"
    /// does not open with "move".
    func remainder(after prefixes: [String]) -> String? {
        let hit = prefixes.sorted { $0.count > $1.count }.first { prefix in
            text == prefix || text.hasPrefix(prefix + " ")
        }
        guard let hit else { return nil }
        return String(text.dropFirst(hit.count)).trimmingCharacters(in: .whitespaces)
    }

    func isOne(of phrases: [String]) -> Bool {
        phrases.contains(text)
    }

    /// Still being typed toward one of `phrases`: "close ta" is on its way to
    /// "close tab", and must not be read as a request of its own.
    func isTyping(toward phrases: [String]) -> Bool {
        phrases.contains { $0.hasPrefix(text) }
    }
}

extension String {
    /// Drops `prefix` and `suffix` when present, trimming what remains.
    func trimming(prefix: String = "", suffix: String = "") -> String {
        var value = self
        if !prefix.isEmpty, value.hasPrefix(prefix) { value = String(value.dropFirst(prefix.count)) }
        if !suffix.isEmpty, value.hasSuffix(suffix) { value = String(value.dropLast(suffix.count)) }
        return value.trimmingCharacters(in: .whitespaces)
    }
}
