import Foundation

/// Built-in engine id or a custom `%s` search template from MDM.
public enum ManagedDefaultSearchEngine: Sendable, Equatable {
    case builtIn(SearchEngine)
    case customTemplate(String)

    /// Parses a forced `DefaultSearchEngine` plist string.
    public init?(forcedValue raw: String) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if let engine = SearchEngine(rawValue: trimmed.lowercased()) {
            self = .builtIn(engine)
            return
        }
        if case .success(let template) = CustomSearchTemplate.validated(trimmed) {
            self = .customTemplate(template)
            return
        }
        return nil
    }
}
