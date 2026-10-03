import CryptoKit
import Foundation

public struct SyncCryptography: Sendable {
    private static let currentProtocolVersion: UInt16 = 1

    public init() {}

    public func makeRootKey() -> Data {
        SymmetricKey(size: .bits256).withUnsafeBytes { Data($0) }
    }

    public func deriveVaultKey(rootKey: Data) throws -> SymmetricKey {
        try deriveKey(rootKey: rootKey, domain: "redent.sync.vault.v1")
    }

    public func deriveWorkspaceKey(rootKey: Data) throws -> SymmetricKey {
        try deriveKey(rootKey: rootKey, domain: "redent.sync.workspace.v1")
    }

    public func encrypt(_ plaintext: Data, using key: SymmetricKey,
                        context: SyncCryptoContext) throws -> SyncEncryptedEnvelope {
        guard key.bitCount == 256 else { throw SyncCryptoError.invalidKeyLength }
        try validate(context)
        let aad = Self.authenticatedData(context)
        let sealed = try AES.GCM.seal(plaintext, using: key, authenticating: aad)
        return SyncEncryptedEnvelope(protocolVersion: context.protocolVersion, nonce: Data(sealed.nonce),
                                     ciphertext: sealed.ciphertext, authenticationTag: sealed.tag)
    }

    public func decrypt(_ envelope: SyncEncryptedEnvelope, using key: SymmetricKey,
                        context: SyncCryptoContext) throws -> Data {
        guard key.bitCount == 256 else { throw SyncCryptoError.invalidKeyLength }
        try validate(context)
        guard envelope.protocolVersion == context.protocolVersion,
              envelope.protocolVersion == Self.currentProtocolVersion else {
            throw SyncCryptoError.unsupportedProtocolVersion
        }
        do {
            let box = try AES.GCM.SealedBox(nonce: AES.GCM.Nonce(data: envelope.nonce),
                                            ciphertext: envelope.ciphertext, tag: envelope.authenticationTag)
            return try AES.GCM.open(box, using: key, authenticating: Self.authenticatedData(context))
        } catch {
            throw SyncCryptoError.authenticationFailed
        }
    }

    private func deriveKey(rootKey: Data, domain: String) throws -> SymmetricKey {
        guard rootKey.count == 32 else { throw SyncCryptoError.invalidKeyLength }
        let derived = HKDF<SHA256>.deriveKey(inputKeyMaterial: SymmetricKey(data: rootKey),
                                             salt: Data("redent.sync.hkdf.v1".utf8),
                                             info: Data(domain.utf8), outputByteCount: 32)
        return derived
    }

    private func validate(_ context: SyncCryptoContext) throws {
        guard context.protocolVersion == Self.currentProtocolVersion else {
            throw SyncCryptoError.unsupportedProtocolVersion
        }
        guard context.keyEpoch > 0, !context.collection.isEmpty,
              context.collection.utf8.count <= 255 else { throw SyncCryptoError.invalidContext }
    }

    private static func authenticatedData(_ context: SyncCryptoContext) -> Data {
        var data = Data("redent.sync.record.v1".utf8)
        data.append(context.protocolVersion.bigEndianData)
        data.append(contentsOf: context.accountID.uuidString.lowercased().utf8)
        data.append(contentsOf: context.recordID.uuidString.lowercased().utf8)
        data.append(UInt32(context.collection.utf8.count).bigEndianData)
        data.append(contentsOf: context.collection.utf8)
        data.append(context.keyEpoch.bigEndianData)
        data.append(context.payloadVersion.bigEndianData)
        return data
    }
}

private extension FixedWidthInteger {
    var bigEndianData: Data {
        var value = bigEndian
        return withUnsafeBytes(of: &value) { Data($0) }
    }
}
