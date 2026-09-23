import Foundation

/// A row in the address bar's dropdown.
public struct AddressSuggestion: Identifiable, Hashable, Sendable {
    public enum Kind: String, Sendable, Hashable {
        case history, bookmark, search, directURL, openTab

        public var symbol: String {
            switch self {
            case .history: "clock"
            case .bookmark: "star.fill"
            case .search: "magnifyingglass"
            case .directURL: "arrow.up.right"
            case .openTab: "square.on.square"
            }
        }
    }

    public private(set) var id: String
    public let kind: Kind
    public let title: String
    public let subtitle: String
    public let url: URL
    public let faviconData: Data?
    /// Set only for `.openTab`: opening the row selects this tab instead of
    /// loading the page a second time.
    public private(set) var tabID: UUID?

    public init(kind: Kind, title: String, subtitle: String, url: URL, faviconData: Data? = nil) {
        self.id = "\(kind.rawValue):\(url.absoluteString)"
        self.kind = kind
        self.title = title
        self.subtitle = subtitle
        self.url = url
        self.faviconData = faviconData
    }

    public static func openTab(_ tabID: UUID, title: String, url: URL, faviconData: Data?) -> AddressSuggestion {
        let host = Origin(url: url)?.displayHost ?? url.absoluteString
        var row = AddressSuggestion(kind: .openTab, title: title, subtitle: host, url: url, faviconData: faviconData)
        row.id = "openTab:\(tabID.uuidString)"
        row.tabID = tabID
        return row
    }
}
