import Foundation

public struct BrowserGroup: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public let spaceID: UUID
    public var name: String
    public var colorToken: String
    public var tabIDs: [UUID]
    /// True while `name` is the site the browser named the group after, so a
    /// generated label may stand in for it. Renaming clears it.
    public var isNameAutomatic: Bool

    public init(
        id: UUID = UUID(), spaceID: UUID, name: String, colorToken: String = "blue",
        tabIDs: [UUID] = [], isNameAutomatic: Bool = false
    ) {
        self.id = id
        self.spaceID = spaceID
        self.name = name
        self.colorToken = colorToken
        self.tabIDs = tabIDs
        self.isNameAutomatic = isNameAutomatic
    }

    private enum CodingKeys: String, CodingKey {
        case id, spaceID, name, colorToken, tabIDs, isNameAutomatic
    }

    /// Explicit so groups saved before `isNameAutomatic` existed still load.
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(UUID.self, forKey: .id)
        spaceID = try values.decode(UUID.self, forKey: .spaceID)
        name = try values.decode(String.self, forKey: .name)
        colorToken = try values.decode(String.self, forKey: .colorToken)
        tabIDs = try values.decode([UUID].self, forKey: .tabIDs)
        isNameAutomatic = try values.decodeIfPresent(Bool.self, forKey: .isNameAutomatic) ?? false
    }
}
