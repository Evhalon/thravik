import Foundation

public struct WorkspaceSyncSnapshot: Sendable, Equatable {
    public var catalog: SyncSpaceCatalog?
    public var deviceTabs: [SyncDeviceTabs]
    public var localDeviceID: UUID

    public init(catalog: SyncSpaceCatalog?, deviceTabs: [SyncDeviceTabs], localDeviceID: UUID) {
        self.catalog = catalog
        self.deviceTabs = deviceTabs
        self.localDeviceID = localDeviceID
    }
}
