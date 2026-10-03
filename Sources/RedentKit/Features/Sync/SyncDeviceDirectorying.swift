import Foundation

public protocol SyncDeviceDirectorying: Sendable {
    func bootstrap(_ identity: SyncDevicePublicIdentity, credential: Data, session: AccountSession) async throws
    func enroll(_ identity: SyncDevicePublicIdentity, credential: Data, expiresAt: Date,
                session: AccountSession) async throws
    func list(session: AccountSession) async throws -> [SyncDeviceRecord]
    func approve(_ approval: SyncDeviceApproval, credential: Data, session: AccountSession) async throws
    func envelope(deviceID: UUID, credential: Data, session: AccountSession) async throws -> SyncDeviceApproval?
    func revoke(deviceID: UUID, approverID: UUID, credential: Data, session: AccountSession) async throws
    func publishClaim(_ claimKey: Data, session: AccountSession) async throws
    func claim(deviceID: UUID, credential: Data, claimKey: Data, session: AccountSession) async throws
}
