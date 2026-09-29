import Foundation
import RedentKit

/// Where an import lands. Bookmarks and logins belong to a Space, so bringing
/// a browser profile across means choosing which profile receives it — that is
/// what makes "one Space per account" work.
public struct ImportDestination: Sendable {
    public let spaces: [BrowserSpace]
    public var spaceID: UUID?

    public init(spaces: [BrowserSpace], spaceID: UUID?) {
        self.spaces = spaces
        self.spaceID = spaceID ?? spaces.first?.id
    }

    public var name: String {
        spaces.first { $0.id == spaceID }?.name ?? "this Space"
    }
}
