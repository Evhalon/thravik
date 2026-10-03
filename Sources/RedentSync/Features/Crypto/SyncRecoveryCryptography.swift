import CryptoKit
import Foundation

public struct SyncRecoveryCryptography: Sendable {
    private let cryptography = SyncCryptography()
    private let recordID = UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1))

    public init() {}

    public func createBundle(rootKey: Data, accountID: UUID) throws -> RecoveryKeyBundle {
        guard rootKey.count == 32 else { throw SyncCryptoError.invalidKeyLength }
        let secret = SymmetricKey(size: .bits256).withUnsafeBytes { Data($0) }
        let code = Self.encode(secret)
        let key = Self.derive(secret: secret, accountID: accountID)
        let context = Self.context(accountID: accountID, recordID: recordID)
        return RecoveryKeyBundle(recoveryCode: code,
                                 wrappedRootKey: try cryptography.encrypt(rootKey, using: key, context: context))
    }

    /// Separate from the wrap key so the server can see a claim key without unlocking the vault.
    public func claimKey(code: String, accountID: UUID) throws -> Data {
        guard let secret = Self.decode(code) else { throw SyncCryptoError.invalidRecoveryCode }
        let derived = HKDF<SHA256>.deriveKey(inputKeyMaterial: SymmetricKey(data: secret),
                                             salt: Data(accountID.uuidString.lowercased().utf8),
                                             info: Data("redent.sync.recovery.claim.v1".utf8), outputByteCount: 32)
        return derived.withUnsafeBytes { Data($0) }
    }

    public func recoverRootKey(code: String, accountID: UUID,
                               envelope: SyncEncryptedEnvelope) throws -> Data {
        guard let secret = Self.decode(code) else { throw SyncCryptoError.invalidRecoveryCode }
        let key = Self.derive(secret: secret, accountID: accountID)
        return try cryptography.decrypt(envelope, using: key,
                                        context: Self.context(accountID: accountID, recordID: recordID))
    }

    private static func context(accountID: UUID, recordID: UUID) -> SyncCryptoContext {
        SyncCryptoContext(accountID: accountID, recordID: recordID, collection: "recovery.root-key",
                          keyEpoch: 1, payloadVersion: 1)
    }

    private static func derive(secret: Data, accountID: UUID) -> SymmetricKey {
        HKDF<SHA256>.deriveKey(inputKeyMaterial: SymmetricKey(data: secret),
                               salt: Data(accountID.uuidString.lowercased().utf8),
                               info: Data("redent.sync.recovery.wrap.v1".utf8), outputByteCount: 32)
    }

    private static func encode(_ secret: Data) -> String {
        let checksum = SHA256.hash(data: Data("redent.sync.recovery.check.v1".utf8) + secret)
        return secret.map { String(format: "%02x", $0) }.joined() + "-" +
            checksum.prefix(4).map { String(format: "%02x", $0) }.joined()
    }

    private static func decode(_ code: String) -> Data? {
        let parts = code.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 2, parts[0].count == 64, parts[1].count == 8,
              let secret = Data(hex: String(parts[0])), encode(secret).hasSuffix("-" + parts[1]) else {
            return nil
        }
        return secret
    }
}

private extension Data {
    init?(hex: String) {
        guard hex.count.isMultiple(of: 2) else { return nil }
        var bytes = [UInt8]()
        var index = hex.startIndex
        while index < hex.endIndex {
            let end = hex.index(index, offsetBy: 2)
            guard let byte = UInt8(hex[index..<end], radix: 16) else { return nil }
            bytes.append(byte)
            index = end
        }
        self.init(bytes)
    }
}
