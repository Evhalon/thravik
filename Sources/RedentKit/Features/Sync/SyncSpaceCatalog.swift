import Foundation

/// Shared structure. Live tab sessions stay on the device that opened them.
public struct SyncSpaceCatalog: Codable, Sendable, Equatable {
    public static let schemaVersion = 1
    public static let recordID = UUID(uuid: (0x52, 0x44, 0x4E, 0x54, 0x57, 0x4B, 0x00, 0x01,
                                              0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01))

    public var schemaVersion: Int
    public var spaces: [SyncSpace]
    public var groups: [BrowserGroup]
    public var pins: [SyncTabSnapshot]
    public var retiredSpaceIDs: [UUID]
    public var retiredGroupIDs: [UUID]
    public var profile: BrowserProfile?

    public init(session: BrowserSession, retiredSpaceIDs: [UUID] = [], retiredGroupIDs: [UUID] = []) {
        schemaVersion = Self.schemaVersion
        spaces = session.spaces.enumerated().map { index, space in
            SyncSpace(id: space.id, name: space.name, icon: space.icon,
                      colorToken: space.colorToken, order: index)
        }
        pins = session.tabs.filter(\.isPinned).compactMap(SyncTabSnapshot.init(tab:))
        let pinIDs = Set(pins.map(\.id))
        groups = session.groups.map { group in
            var copy = group
            copy.tabIDs = group.tabIDs.filter { pinIDs.contains($0) }
            return copy
        }
        self.retiredSpaceIDs = retiredSpaceIDs
        self.retiredGroupIDs = retiredGroupIDs
        profile = session.profile
    }
}
