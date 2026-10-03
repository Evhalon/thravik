import Foundation

public struct PasswordKeyEnvelope: Sendable, Equatable, Codable {
    public let protocolVersion: UInt16
    public let kdf: String
    public let iterations: UInt32
    public let salt: Data
    public let nonce: Data
    public let ciphertext: Data
    public let authenticationTag: Data

    public init(salt: Data, encrypted: SyncEncryptedEnvelope) {
        protocolVersion = 1
        kdf = "pbkdf2-hmac-sha256"
        iterations = SyncPasswordKeyDerivation.iterations
        self.salt = salt
        nonce = encrypted.nonce
        ciphertext = encrypted.ciphertext
        authenticationTag = encrypted.authenticationTag
    }
}
