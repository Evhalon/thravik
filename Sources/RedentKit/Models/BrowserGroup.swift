import Foundation

public struct BrowserGroup: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public let spaceID: UUID
    public var name: String
    public var colorToken: String
    public var tabIDs: [UUID]

    public init(
        id: UUID = UUID(), spaceID: UUID, name: String, colorToken: String = "blue", tabIDs: [UUID] = []
    ) {
        self.id = id
        self.spaceID = spaceID
        self.name = name
        self.colorToken = colorToken
        self.tabIDs = tabIDs
    }
}
