import Foundation

public struct SyncWriteRequest: Sendable {
    public let identity: SyncRecordIdentity
    public let expectedRevision: Int64
    public let plaintext: Data
    public let isDeleted: Bool
    public let keyEpoch: UInt64

    public init(identity: SyncRecordIdentity, expectedRevision: Int64, plaintext: Data,
                isDeleted: Bool = false, keyEpoch: UInt64 = 1) {
        self.identity = identity
        self.expectedRevision = expectedRevision
        self.plaintext = plaintext
        self.isDeleted = isDeleted
        self.keyEpoch = keyEpoch
    }
}
