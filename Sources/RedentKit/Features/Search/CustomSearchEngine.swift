import Foundation

public struct CustomSearchEngine: Codable, Sendable, Identifiable, Equatable, Hashable {
    public let id: UUID
    public var name: String
    public var keyword: String
    public var template: String

    public init(id: UUID = UUID(), name: String, keyword: String, template: String) {
        self.id = id
        self.name = name
        self.keyword = keyword
        self.template = template
    }

    public func searchURL(for query: String) -> URL? {
        CustomSearchTemplate.url(from: template, query: query)
    }

    public var homepage: String? {
        guard let url = searchURL(for: "x"), let scheme = url.scheme, let host = url.host() else { return nil }
        return "\(scheme)://\(host)"
    }

    public static func make(
        name: String,
        keyword: String,
        template: String,
        existing: [CustomSearchEngine]
    ) -> Result<CustomSearchEngine, CustomSearchEngineError> {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return .failure(.emptyName) }
        let trimmedKeyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard isValidKeyword(trimmedKeyword) else { return .failure(.invalidKeyword) }
        guard !existing.contains(where: { $0.keyword.lowercased() == trimmedKeyword }) else {
            return .failure(.duplicateKeyword)
        }
        switch CustomSearchTemplate.validated(template) {
        case .failure(let error): return .failure(error)
        case .success(let valid):
            return .success(CustomSearchEngine(name: trimmedName, keyword: trimmedKeyword, template: valid))
        }
    }

    private static func isValidKeyword(_ keyword: String) -> Bool {
        guard !keyword.isEmpty, !keyword.contains(where: \.isWhitespace) else { return false }
        return keyword.allSatisfy { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" }
    }
}
