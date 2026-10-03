import Foundation
import RedentKit

struct SupabaseSyncRecord: Codable {
    let mutationID: UUID
    let collection: String
    let recordID: UUID
    let expectedRevision: Int64
    let encryptedPayload: String
    let deleted: Bool
    var revision: Int64?
    var cursor: Int64?
    var status: String?
    var deviceID: UUID?
    var deviceCredential: String?
    var signature: String?
    var signerDeviceID: UUID?

    enum CodingKeys: String, CodingKey {
        case mutationID = "mutation_id", recordID = "record_id", expectedRevision = "expected_revision"
        case encryptedPayload = "encrypted_payload", collection, deleted, revision, cursor, status
        case deviceID = "device_id", deviceCredential = "device_credential", signature
        case signerDeviceID = "signer_device_id"
    }

    init(mutation: SyncMutation, proof: SyncDeviceProof?) {
        mutationID = mutation.id
        collection = mutation.identity.collection
        recordID = mutation.identity.recordID
        expectedRevision = mutation.expectedRevision
        encryptedPayload = mutation.encryptedPayload.base64EncodedString()
        deleted = mutation.isDeleted
        deviceID = proof?.deviceID
        deviceCredential = proof?.credential.base64EncodedString()
        signature = proof?.signature.base64EncodedString()
        revision = nil
        cursor = nil
        status = nil
        signerDeviceID = nil
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(mutationID, forKey: .mutationID)
        try container.encode(collection, forKey: .collection)
        try container.encode(recordID, forKey: .recordID)
        try container.encode(expectedRevision, forKey: .expectedRevision)
        try container.encode(encryptedPayload, forKey: .encryptedPayload)
        try container.encode(deleted, forKey: .deleted)
        try container.encodeIfPresent(revision, forKey: .revision)
        try container.encodeIfPresent(cursor, forKey: .cursor)
        try container.encodeIfPresent(status, forKey: .status)
        try container.encodeIfPresent(deviceID, forKey: .deviceID)
        try container.encodeIfPresent(deviceCredential, forKey: .deviceCredential)
        try container.encodeIfPresent(signature, forKey: .signature)
        try container.encodeIfPresent(signerDeviceID, forKey: .signerDeviceID)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        mutationID = try container.decode(UUID.self, forKey: .mutationID)
        collection = try container.decode(String.self, forKey: .collection)
        recordID = try container.decode(UUID.self, forKey: .recordID)
        expectedRevision = try container.decode(Int64.self, forKey: .expectedRevision)
        encryptedPayload = try container.decode(String.self, forKey: .encryptedPayload)
        deleted = try container.decode(Bool.self, forKey: .deleted)
        revision = try container.decodeIfPresent(Int64.self, forKey: .revision)
        cursor = try container.decodeIfPresent(Int64.self, forKey: .cursor)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        deviceID = try container.decodeIfPresent(UUID.self, forKey: .deviceID)
        deviceCredential = try container.decodeIfPresent(String.self, forKey: .deviceCredential)
        signature = try container.decodeIfPresent(String.self, forKey: .signature)
        signerDeviceID = try container.decodeIfPresent(UUID.self, forKey: .signerDeviceID)
    }

    func record(accountID: UUID) throws -> SyncRemoteRecord {
        guard let payload = Data(base64Encoded: encryptedPayload), let revision, let cursor,
              status == nil || status == "accepted" else { throw SyncError.invalidResponse }
        let identity = SyncRecordIdentity(accountID: accountID, collection: collection, recordID: recordID)
        let mutation = SyncMutation(id: mutationID, identity: identity, expectedRevision: expectedRevision,
                                    encryptedPayload: payload, isDeleted: deleted)
        try SyncMutationValidation.validate(mutation)
        let signer = signerDeviceID ?? deviceID
        let signatureData = try Self.signatureBytes(signature)
        guard (signer == nil) == (signatureData == nil) else { throw SyncError.invalidResponse }
        return SyncRemoteRecord(mutation: mutation, revision: revision, cursor: cursor,
                                signerDeviceID: signer, signature: signatureData)
    }

    private static func signatureBytes(_ encoded: String?) throws -> Data? {
        guard let encoded else { return nil }
        guard let data = Data(base64Encoded: encoded), data.count == 64 else { throw SyncError.invalidResponse }
        return data
    }
}
