import Foundation

/// A row in the address bar's dropdown.
public struct AddressSuggestion: Identifiable, Hashable, Sendable {
    public enum Kind: String, Sendable, Hashable {
        case history, bookmark, search, directURL

        public var symbol: String {
            switch self {
            case .history: "clock"
            case .bookmark: "star.fill"
            case .search: "magnifyingglass"
            case .directURL: "arrow.up.right"
            }
        }
    }

    public let id: String
    public let kind: Kind
    public let title: String
    public let subtitle: String
    public let url: URL
    public let faviconData: Data?
    public let score: Double

    public init(
        kind: Kind,
        title: String,
        subtitle: String,
        url: URL,
        faviconData: Data? = nil,
        score: Double
    ) {
        self.id = "\(kind.rawValue):\(url.absoluteString)"
        self.kind = kind
        self.title = title
        self.subtitle = subtitle
        self.url = url
        self.faviconData = faviconData
        self.score = score
    }
}
