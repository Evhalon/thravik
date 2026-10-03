import Foundation

/// Unpinned tabs open on one Mac. Another Mac lists them; it does not load them.
public struct SyncDeviceTabs: Codable, Sendable, Equatable {
    public static let schemaVersion = 1

    public var schemaVersion: Int
    public let deviceID: UUID
    public var tabs: [SyncTabSnapshot]

    public init(session: BrowserSession, deviceID: UUID) {
        schemaVersion = Self.schemaVersion
        self.deviceID = deviceID
        tabs = session.tabs.compactMap(SyncTabSnapshot.init(tab:)).filter { !$0.isPinned }
    }
}
