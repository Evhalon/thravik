import Foundation
import RedentKit

public struct WorkspaceSyncDependencies: Sendable {
    public let replica: any AuthenticatedSyncStoring
    public let keys: any SyncKeyStoring
    public let deviceKeys: any SyncDeviceKeyStoring
    public let transport: any SyncTransporting
    public let sessions: any AccountSessionStoring

    public init(replica: any AuthenticatedSyncStoring, keys: any SyncKeyStoring,
                deviceKeys: any SyncDeviceKeyStoring, transport: any SyncTransporting,
                sessions: any AccountSessionStoring) {
        self.replica = replica
        self.keys = keys
        self.deviceKeys = deviceKeys
        self.transport = transport
        self.sessions = sessions
    }
}
