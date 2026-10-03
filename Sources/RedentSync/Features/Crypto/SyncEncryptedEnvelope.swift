import Foundation

public struct SyncEncryptedEnvelope: Sendable, Equatable {
    public let protocolVersion: UInt16
    public let nonce: Data
    public let ciphertext: Data
    public let authenticationTag: Data

    public init(protocolVersion: UInt16, nonce: Data, ciphertext: Data, authenticationTag: Data) {
        self.protocolVersion = protocolVersion
        self.nonce = nonce
        self.ciphertext = ciphertext
        self.authenticationTag = authenticationTag
    }
}
