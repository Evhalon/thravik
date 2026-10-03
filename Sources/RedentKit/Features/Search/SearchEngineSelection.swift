import Foundation

public enum SearchEngineSelection: Hashable, Sendable, Identifiable {
    case builtIn(SearchEngine)
    case custom(UUID)

    public var id: String {
        switch self {
        case .builtIn(let engine): "builtin:\(engine.rawValue)"
        case .custom(let id): "custom:\(id.uuidString)"
        }
    }
}
