import Foundation
import RedentKit

public enum CommandResultSource: String, Hashable, Sendable {
    case command
    case tab
    case space
    case bookmark
    case history
    case directURL
    case search

    public var symbol: String {
        switch self {
        case .command: "command"
        case .tab: "rectangle.on.rectangle"
        case .space: "square.3.layers.3d"
        case .bookmark: "star.fill"
        case .history: "clock"
        case .directURL: "arrow.up.right"
        case .search: "magnifyingglass"
        }
    }
}

public struct CommandBarResult: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let source: CommandResultSource
    public let symbol: String
    public let action: BrowserAction?

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
