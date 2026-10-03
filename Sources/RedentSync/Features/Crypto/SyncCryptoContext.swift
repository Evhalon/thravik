import Foundation

public struct SyncCryptoContext: Sendable, Equatable {
    public let accountID: UUID
    public let recordID: UUID
    public let collection: String
    public let keyEpoch: UInt64
    public let protocolVersion: UInt16
    public let payloadVersion: UInt32

    public init(accountID: UUID, recordID: UUID, collection: String, keyEpoch: UInt64,
                payloadVersion: UInt32) {
        self.accountID = accountID
        self.recordID = recordID
        self.collection = collection
        self.keyEpoch = keyEpoch
        self.protocolVersion = 1
        self.payloadVersion = payloadVersion
    }
}
