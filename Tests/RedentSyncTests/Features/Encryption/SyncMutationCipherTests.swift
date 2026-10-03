import Foundation
import Testing
import RedentKit
@testable import RedentSync

struct SyncMutationCipherTests {
    @Test func authenticatesMutationMetadata() throws {
        let identity = SyncRecordIdentity(accountID: UUID(), collection: "workspace", recordID: UUID())
        let key = SyncCryptography().makeRootKey()
        let cipher = SyncMutationCipher()
        let value = Data("sensitive value".utf8)
        let encrypted = try cipher.encrypt(SyncWriteRequest(identity: identity, expectedRevision: 0,
                                                            plaintext: value), rootKey: key)
        #expect(try cipher.decrypt(encrypted, rootKey: key) == value)
        let modified = SyncMutation(id: encrypted.id, identity: identity, expectedRevision: 0,
                                    encryptedPayload: encrypted.encryptedPayload, isDeleted: true)
        #expect(throws: SyncCryptoError.authenticationFailed) { try cipher.decrypt(modified, rootKey: key) }
        let replayed = SyncMutation(identity: identity, expectedRevision: 0,
                                    encryptedPayload: encrypted.encryptedPayload)
        #expect(throws: SyncCryptoError.authenticationFailed) { try cipher.decrypt(replayed, rootKey: key) }
    }

    @Test func refusesUnclassifiedCollections() throws {
        let identity = SyncRecordIdentity(accountID: UUID(), collection: "new_secrets", recordID: UUID())
        let request = SyncWriteRequest(identity: identity, expectedRevision: 0, plaintext: Data())
        #expect(throws: SyncError.invalidMutation) {
            try SyncMutationCipher().encrypt(request, rootKey: SyncCryptography().makeRootKey())
        }
    }

    @Test func rejectsAnotherAccountAndKeyEpoch() throws {
        let identity = SyncRecordIdentity(accountID: UUID(), collection: "workspace", recordID: UUID())
        let key = SyncCryptography().makeRootKey()
        let cipher = SyncMutationCipher()
        let original = try cipher.encrypt(SyncWriteRequest(identity: identity, expectedRevision: 0,
                                                           plaintext: Data()), rootKey: key)
        let other = SyncRecordIdentity(accountID: UUID(), collection: identity.collection, recordID: identity.recordID)
        let modified = SyncMutation(id: original.id, identity: other, expectedRevision: 0,
                                    encryptedPayload: original.encryptedPayload)
        #expect(throws: SyncCryptoError.authenticationFailed) { try cipher.decrypt(modified, rootKey: key) }
        let invalid = SyncWriteRequest(identity: identity, expectedRevision: 0, plaintext: Data(), keyEpoch: 0)
        #expect(throws: SyncCryptoError.self) { try cipher.encrypt(invalid, rootKey: key) }
    }
}
