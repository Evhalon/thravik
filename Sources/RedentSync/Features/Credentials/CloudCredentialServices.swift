import RedentKit

public struct CloudCredentialServices: Sendable {
    public let replica: any AuthenticatedSyncStoring
    public let keys: any SyncKeyStoring
    public let transport: any SyncTransporting
    public let sessions: any AccountSessionStoring

    public init(replica: any AuthenticatedSyncStoring, keys: any SyncKeyStoring,
                transport: any SyncTransporting, sessions: any AccountSessionStoring) {
        self.replica = replica
        self.keys = keys
        self.transport = transport
        self.sessions = sessions
    }
}
