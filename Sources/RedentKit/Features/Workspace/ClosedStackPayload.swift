import Foundation

public enum ClosedStackPayload: Sendable, Hashable, Codable {
    case tab(TabSnapshot)
    case group(group: BrowserGroup, tabs: [TabSnapshot])
}
