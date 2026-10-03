import CryptoKit
import Foundation
import RedentKit

public struct SyncMutationCipher: SyncMutationCiphering {
    private let crypto = SyncCryptography()

    public init() {}

    public func encrypt(_ request: SyncWriteRequest, rootKey: Data) throws -> SyncMutation {
        let mutationID = UUID()
        let payload = SyncProtectedPayload(mutation: mutationID, expectedRevision: request.expectedRevision,
                                           deleted: request.isDeleted, value: request.plaintext)
        let context = context(identity: request.identity, epoch: request.keyEpoch)
        let key = try key(rootKey: rootKey, collection: request.identity.collection)
        let envelope = try crypto.encrypt(JSONEncoder().encode(payload), using: key, context: context)
        let stored = EncryptedSyncMutation(keyEpoch: request.keyEpoch, nonce: envelope.nonce,
                                           ciphertext: envelope.ciphertext, tag: envelope.authenticationTag)
        let mutation = SyncMutation(id: mutationID, identity: request.identity,
                                    expectedRevision: request.expectedRevision,
                                    encryptedPayload: try JSONEncoder().encode(stored), isDeleted: request.isDeleted)
        try SyncMutationValidation.validate(mutation)
        return mutation
    }

    public func decrypt(_ mutation: SyncMutation, rootKey: Data) throws -> Data {
        try SyncMutationValidation.validate(mutation)
        guard let stored = try? JSONDecoder().decode(EncryptedSyncMutation.self, from: mutation.encryptedPayload)
        else { throw SyncCryptoError.authenticationFailed }
        let envelope = SyncEncryptedEnvelope(protocolVersion: 1, nonce: stored.nonce,
                                              ciphertext: stored.ciphertext, authenticationTag: stored.tag)
        let key = try key(rootKey: rootKey, collection: mutation.identity.collection)
        let plaintext = try crypto.decrypt(envelope, using: key,
                                          context: context(identity: mutation.identity, epoch: stored.keyEpoch))
        guard let payload = try? JSONDecoder().decode(SyncProtectedPayload.self, from: plaintext)
        else { throw SyncCryptoError.authenticationFailed }
        try payload.verify(mutation)
        return payload.value
    }

    private func key(rootKey: Data, collection: String) throws -> SymmetricKey {
        if collection == "credentials" || collection == "totp" {
            return try crypto.deriveVaultKey(rootKey: rootKey)
        }
        let workspaceCollections = ["workspace", "spaces", "groups", "pins", "device_tabs",
                                    "bookmarks", "bookmark_folders", "settings", "history"]
        guard workspaceCollections.contains(collection) else { throw SyncError.invalidMutation }
        return try crypto.deriveWorkspaceKey(rootKey: rootKey)
    }

    private func context(identity: SyncRecordIdentity, epoch: UInt64) -> SyncCryptoContext {
        SyncCryptoContext(accountID: identity.accountID, recordID: identity.recordID,
                          collection: identity.collection, keyEpoch: epoch, payloadVersion: 1)
    }
}
