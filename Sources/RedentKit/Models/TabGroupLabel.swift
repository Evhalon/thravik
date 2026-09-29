import Foundation

/// Turns a generated group name into something fit for a sidebar header.
public enum TabGroupLabel: Sendable {
    public static let maximumWords = 3
    public static let maximumLength = 28

    /// Nil when nothing usable is left, so the site name stays.
    public static func sanitized(_ raw: String) -> String? {
        let unquoted = raw.trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
        let words = unquoted.split(whereSeparator: \.isWhitespace).prefix(maximumWords)
        let label = words.joined(separator: " ")
        guard !label.isEmpty, label.count <= maximumLength else { return nil }
        return label
    }

    /// The pages a namer is shown: enough to read the topic, bounded so a
    /// crowded group costs the same as a small one. The lead-in is not
    /// decoration: the on-device model guesses the prompt's language before
    /// answering, and a bare list of short titles ("Voli per Lisbona", "Hotel
    /// a Lisbona") reads as no language at all and is refused as unsupported.
    public static func prompt(for pages: [TabGroupPage], limit: Int = 8) -> String {
        let lines = pages.prefix(limit).map { "- \($0.title.prefix(80)) (\($0.host))" }
        return ([promptLeadIn] + lines).joined(separator: "\n")
    }

    static let promptLeadIn = "Name the topic shared by these open browser tabs, listed as title followed by site:"
}
