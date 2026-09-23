import Foundation

/// A tab group as the Command Bar lists it.
public struct CommandGroupContext: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let name: String
    public let spaceID: UUID
    public let spaceName: String?
    public let tabIDs: [UUID]

    public init(id: UUID, name: String, spaceID: UUID, spaceName: String? = nil, tabIDs: [UUID] = []) {
        self.id = id
        self.name = name
        self.spaceID = spaceID
        self.spaceName = spaceName
        self.tabIDs = tabIDs
    }
}
