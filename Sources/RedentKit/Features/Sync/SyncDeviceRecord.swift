import Foundation

public struct SyncDeviceRecord: Sendable, Equatable, Identifiable {
    public let id: UUID
    public let agreementPublicKey: Data
    public let signingPublicKey: Data
    public let status: SyncDeviceStatus
    public let expiresAt: Date?

    public init(id: UUID, agreementPublicKey: Data, signingPublicKey: Data,
                status: SyncDeviceStatus, expiresAt: Date?) {
        self.id = id
        self.agreementPublicKey = agreementPublicKey
        self.signingPublicKey = signingPublicKey
        self.status = status
        self.expiresAt = expiresAt
    }

    public var identity: SyncDevicePublicIdentity {
        SyncDevicePublicIdentity(id: id, agreementPublicKey: agreementPublicKey,
                                 signingPublicKey: signingPublicKey)
    }
}
