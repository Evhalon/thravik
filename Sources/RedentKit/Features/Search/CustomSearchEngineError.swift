import Foundation

public enum CustomSearchEngineError: Error, Equatable, Sendable {
    case emptyName
    case invalidKeyword
    case duplicateKeyword
    case invalidTemplate
    case missingQueryPlaceholder

    public var message: String {
        switch self {
        case .emptyName: "Name is required."
        case .invalidKeyword: "Keyword must be one word."
        case .duplicateKeyword: "That keyword is already used."
        case .invalidTemplate: "Use an http(s) URL."
        case .missingQueryPlaceholder: "Template must contain %s for the query."
        }
    }
}
