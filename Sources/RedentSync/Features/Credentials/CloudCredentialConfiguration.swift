import Foundation
import RedentKit

public struct CloudCredentialConfiguration: Sendable {
    public let accountID: UUID
    public let local: any CredentialSnapshotStoring
    public let replica: any AuthenticatedSyncStoring
    public let keys: any SyncKeyStoring
    public let transport: any SyncTransporting
    public let sessions: any AccountSessionStoring

    public init(accountID: UUID, local: any CredentialSnapshotStoring, services: CloudCredentialServices) {
        self.accountID = accountID
        self.local = local
        replica = services.replica
        keys = services.keys
        transport = services.transport
        sessions = services.sessions
    }
}
