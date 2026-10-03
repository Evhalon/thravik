import Foundation

public enum SearchKeywordResolver {
    public struct Match: Equatable, Sendable {
        public let engine: CustomSearchEngine
        public let query: String
    }

    /// `yt funny cats` — keyword, then a space, then the query.
    public static func match(in text: String, engines: [CustomSearchEngine]) -> Match? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let space = trimmed.firstIndex(of: " ") else { return nil }
        let keyword = trimmed[..<space].lowercased()
        let query = trimmed[trimmed.index(after: space)...].trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return nil }
        guard let engine = engines.first(where: { $0.keyword.lowercased() == keyword }) else { return nil }
        return Match(engine: engine, query: String(query))
    }
}
