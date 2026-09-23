import Foundation
import RedentKit

public enum CommandResultSource: String, Hashable, Sendable {
    case command
    case tab
    case space
    case group
    case window
    case webApp
    case bookmark
    case history
    case directURL
    case search

    public var symbol: String {
        switch self {
        case .command: "command"
        case .tab: "rectangle.on.rectangle"
        case .space: "square.3.layers.3d"
        case .group: "square.stack"
        case .window: "macwindow"
        case .webApp: "app"
        case .bookmark: "star.fill"
        case .history: "clock"
        case .directURL: "arrow.up.right"
        case .search: "magnifyingglass"
        }
    }

    /// The heading a row sits under when the bar lists what is at hand.
    public var section: String {
        switch self {
        case .command: "Actions"
        case .tab: "Tabs"
        case .space, .group: "Spaces"
        case .window: "Windows"
        case .webApp: "Apps"
        case .bookmark: "Bookmarks"
        case .history: "History"
        case .directURL, .search: "Go"
        }
    }
}

public struct CommandBarResult: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let source: CommandResultSource
    public internal(set) var symbol: String
    public let action: BrowserAction?
    /// Pressed, the row fills the field with this instead of running — how a
    /// command asks for its argument ("Move Tab to…" → "move tab to ").
    public internal(set) var completion: String?
    public internal(set) var faviconData: Data?
    /// The host the favicon stands for, used when the page has none.
    public internal(set) var faviconHost: String?

    public init(
        id: String,
        title: String,
        subtitle: String,
        source: CommandResultSource,
        action: BrowserAction? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.source = source
        self.symbol = source.symbol
        self.action = action
    }
}
