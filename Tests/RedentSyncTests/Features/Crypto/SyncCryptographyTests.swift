import CryptoKit
import Foundation
import Testing
@testable import RedentSync

struct SyncCryptographyTests {
    private let crypto = SyncCryptography()

    @Test func roundTripBindsEnvelopeToRecordContext() throws {
        let context = Self.context()
        let key = try crypto.deriveVaultKey(rootKey: crypto.makeRootKey())
        let plaintext = Data("private record".utf8)
        let envelope = try crypto.encrypt(plaintext, using: key, context: context)

        #expect(try crypto.decrypt(envelope, using: key, context: context) == plaintext)
        #expect(throws: SyncCryptoError.self) {
            try crypto.decrypt(envelope, using: key,
                               context: SyncCryptoContext(accountID: UUID(), recordID: context.recordID,
                                                          collection: context.collection, keyEpoch: context.keyEpoch,
                                                          payloadVersion: context.payloadVersion))
        }
    }

    @Test func rejectsChangedCiphertextAndWrongKey() throws {
        let context = Self.context()
        let firstKey = try crypto.deriveVaultKey(rootKey: crypto.makeRootKey())
        let secondKey = try crypto.deriveVaultKey(rootKey: crypto.makeRootKey())
        let envelope = try crypto.encrypt(Data("secret".utf8), using: firstKey, context: context)
        let changed = SyncEncryptedEnvelope(protocolVersion: envelope.protocolVersion, nonce: envelope.nonce,
                                            ciphertext: envelope.ciphertext + Data([1]),
                                            authenticationTag: envelope.authenticationTag)

        #expect(throws: SyncCryptoError.self) { try crypto.decrypt(changed, using: firstKey, context: context) }
        #expect(throws: SyncCryptoError.self) { try crypto.decrypt(envelope, using: secondKey, context: context) }
    }

    @Test func domainsProduceDistinctKeys() throws {
        let rootKey = crypto.makeRootKey()
        let vault = try crypto.deriveVaultKey(rootKey: rootKey)
        let workspace = try crypto.deriveWorkspaceKey(rootKey: rootKey)
        let context = Self.context()
        let envelope = try crypto.encrypt(Data("vault".utf8), using: vault, context: context)

        #expect(throws: SyncCryptoError.self) { try crypto.decrypt(envelope, using: workspace, context: context) }
    }

    private static func context() -> SyncCryptoContext {
        SyncCryptoContext(accountID: UUID(), recordID: UUID(), collection: "passwords", keyEpoch: 3,
                          payloadVersion: 2)
    }
}
