import CryptoKit
import Foundation

public struct SyncPasswordCryptography: Sendable {
    private static let iterations: UInt32 = 600_000
    private static let recordID = UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2))
    private let cryptography = SyncCryptography()

    public init() {}

    public func wrap(recoveryCode: String, password: String, accountID: UUID) throws -> PasswordKeyEnvelope {
        try validatePassword(password)
        guard recoveryCode.utf8.count == 73 else { throw SyncPasswordCryptographyError.invalidEnvelope }
        let salt = Self.randomSalt()
        let key = try SyncPasswordKeyDerivation().derive(password: password, salt: salt)
        let context = Self.context(accountID: accountID)
        let sealed = try cryptography.encrypt(Data(recoveryCode.utf8), using: key, context: context)
        return PasswordKeyEnvelope(salt: salt, encrypted: sealed)
    }

    public func unwrap(envelope: PasswordKeyEnvelope, password: String, accountID: UUID) throws -> String {
        try validatePassword(password)
        try Self.validate(envelope)
        let key = try SyncPasswordKeyDerivation().derive(password: password, salt: envelope.salt)
        let sealed = SyncEncryptedEnvelope(protocolVersion: envelope.protocolVersion, nonce: envelope.nonce,
                                           ciphertext: envelope.ciphertext,
                                           authenticationTag: envelope.authenticationTag)
        var plaintext: Data
        do { plaintext = try cryptography.decrypt(sealed, using: key, context: Self.context(accountID: accountID)) }
        catch { throw SyncPasswordCryptographyError.authenticationFailed }
        defer { plaintext.resetBytes(in: 0..<plaintext.count) }
        guard let code = String(data: plaintext, encoding: .utf8), code.utf8.count == 73 else {
            throw SyncPasswordCryptographyError.authenticationFailed
        }
        return code
    }

    private func validatePassword(_ password: String) throws {
        guard password.count >= 12, password.utf8.count <= 1024 else {
            throw SyncPasswordCryptographyError.invalidPassword
        }
    }

    private static func validate(_ envelope: PasswordKeyEnvelope) throws {
        guard envelope.protocolVersion == 1, envelope.kdf == "pbkdf2-hmac-sha256",
              envelope.iterations == iterations, envelope.salt.count == 32,
              envelope.nonce.count == 12, envelope.ciphertext.count == 73,
              envelope.authenticationTag.count == 16 else {
            throw SyncPasswordCryptographyError.invalidEnvelope
        }
    }

    private static func randomSalt() -> Data {
        SymmetricKey(size: .bits256).withUnsafeBytes { Data($0) }
    }

    private static func context(accountID: UUID) -> SyncCryptoContext {
        SyncCryptoContext(accountID: accountID, recordID: recordID, collection: "password.recovery-code",
                          keyEpoch: 1, payloadVersion: 1)
    }
}
