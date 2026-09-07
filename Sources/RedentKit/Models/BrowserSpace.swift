import Foundation

public struct BrowserSpace: Identifiable, Codable, Sendable, Hashable {
    public static let workID = UUID(uuid: (0x45, 0x44, 0x53, 0x01, 0x00, 0x00, 0x00, 0x00,
                                             0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01))
    public static let personalID = UUID(uuid: (0x45, 0x44, 0x53, 0x02, 0x00, 0x00, 0x00, 0x00,
                                                 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02))
    public static let researchID = UUID(uuid: (0x45, 0x44, 0x53, 0x03, 0x00, 0x00, 0x00, 0x00,
                                                 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03))
    public static let travelID = UUID(uuid: (0x45, 0x44, 0x53, 0x04, 0x00, 0x00, 0x00, 0x00,
                                               0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x04))

    public let id: UUID
    public var name: String
    public var icon: String
    public var colorToken: String
    public var tabIDs: [UUID]
    public var groupIDs: [UUID]
    public var selectedTabID: UUID?
    public var defaultContainerID: UUID

    public init(id: UUID = UUID(), name: String, defaultContainerID: UUID = BrowserContainer.defaultID) {
        self.id = id
        self.name = name
        let look = SpaceIdentity.look(id: id, icon: SpaceIdentity.unsetIcon, colorToken: SpaceIdentity.unsetToken)
        self.icon = look.icon
        self.colorToken = look.colorToken
        self.tabIDs = []
        self.groupIDs = []
        self.selectedTabID = nil
        self.defaultContainerID = defaultContainerID
    }

    public static let starterSpaces: [BrowserSpace] = [
        BrowserSpace(id: workID, name: "Work"),
        BrowserSpace(id: personalID, name: "Personal"),
        BrowserSpace(id: researchID, name: "Research"),
        BrowserSpace(id: travelID, name: "Travel")
    ]
}
