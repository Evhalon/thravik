import Foundation

public struct SyncDeviceApproval: Sendable, Equatable, Codable {
    public let senderDeviceID: UUID
    public let recipientDeviceID: UUID
    public let requestID: UUID
    public let expiresAt: Date
    public let keyEpoch: UInt64
    public let nonce: Data
    public let ciphertext: Data
    public let authenticationTag: Data
    public let signature: Data

    public init(senderDeviceID: UUID, recipientDeviceID: UUID, requestID: UUID, expiresAt: Date,
                keyEpoch: UInt64, nonce: Data, ciphertext: Data, authenticationTag: Data, signature: Data) {
        self.senderDeviceID = senderDeviceID
        self.recipientDeviceID = recipientDeviceID
        self.requestID = requestID
        self.expiresAt = expiresAt
        self.keyEpoch = keyEpoch
        self.nonce = nonce
        self.ciphertext = ciphertext
        self.authenticationTag = authenticationTag
        self.signature = signature
    }
}
