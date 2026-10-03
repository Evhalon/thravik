import Foundation

/// Ciphertext only: plaintext never enters the transport or persistence ports.
public struct SyncMutation: Codable, Sendable, Equatable {
    public let id: UUID
    public let identity: SyncRecordIdentity
    public let expectedRevision: Int64
    public let encryptedPayload: Data
    public let isDeleted: Bool

    public init(id: UUID = UUID(), identity: SyncRecordIdentity, expectedRevision: Int64,
                encryptedPayload: Data, isDeleted: Bool = false) {
        self.id = id
        self.identity = identity
        self.expectedRevision = expectedRevision
        self.encryptedPayload = encryptedPayload
        self.isDeleted = isDeleted
    }
}
