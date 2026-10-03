import Foundation
import RedentKit

actor CloudCredentialProjection {
    private let accountID: UUID
    private let local: any CredentialSnapshotStoring
    private let replica: any AuthenticatedSyncStoring
    private let keys: any SyncKeyStoring
    private let cipher = SyncMutationCipher()

    init(accountID: UUID, local: any CredentialSnapshotStoring,
         replica: any AuthenticatedSyncStoring, keys: any SyncKeyStoring) {
        self.accountID = accountID
        self.local = local
        self.replica = replica
        self.keys = keys
    }

    func restore() async throws {
        let original = Dictionary(try await local.allCredentials().map { ($0.id, $0) },
                                  uniquingKeysWith: { _, last in last })
        var current = original
        let pending = try await replica.pending(accountID: accountID, limit: 10000)
            .filter { $0.identity.collection == "credentials" }
        let pendingIDs = Set(pending.map { $0.identity.recordID })
        let records = try await replica.records(accountID: accountID)
        guard var key = try await keys.load(accountID: accountID) else { throw SyncError.unauthorized }
        defer { key.resetBytes(in: 0..<key.count) }
        for record in records where record.mutation.identity.collection == "credentials" {
            guard !pendingIDs.contains(record.mutation.identity.recordID) else { continue }
            try project(record.mutation, into: &current, key: key)
        }
        for mutation in pending { try project(mutation, into: &current, key: key) }
        guard current != original else { return }
        try await local.applySnapshot(Array(current.values))
    }

    func write(_ credential: Credential?, id: UUID) async throws {
        try await restore()
        let pending = try await replica.pending(accountID: accountID, limit: 10000)
        let existing = pending.first {
            $0.identity.collection == "credentials" && $0.identity.recordID == id
        }
        guard existing != nil || pending.count < 10000 else { throw SyncError.quotaExceeded }
        let identity = SyncRecordIdentity(accountID: accountID, collection: "credentials", recordID: id)
        let records = try await replica.records(accountID: accountID)
        let revision = existing?.expectedRevision ?? records.first { $0.mutation.identity == identity }?.revision ?? 0
        var plaintext = try credential.map { try JSONEncoder().encode(CloudCredentialPayload($0)) } ?? Data()
        defer { plaintext.resetBytes(in: 0..<plaintext.count) }
        let request = SyncWriteRequest(identity: identity, expectedRevision: revision,
                                       plaintext: plaintext, isDeleted: credential == nil)
        if let existing {
            guard var key = try await keys.load(accountID: accountID) else { throw SyncError.unauthorized }
            defer { key.resetBytes(in: 0..<key.count) }
            try await replica.replacePending(existing, with: cipher.encrypt(request, rootKey: key))
        } else {
            let writer = EncryptedSyncWriter(cipher: cipher, keys: keys, local: replica)
            _ = try await writer.enqueue(request)
        }
        // The durable ciphertext is the replay journal if the following Keychain write fails.
        try await restore()
    }

    func importFresh(_ credentials: [Credential]) async throws {
        let pending = try await replica.pending(accountID: accountID, limit: 10000)
        guard pending.count + credentials.count <= 10000 else { throw SyncError.quotaExceeded }
        let pendingIDs = Set(pending.filter { $0.identity.collection == "credentials" }
            .map { $0.identity.recordID })
        guard credentials.allSatisfy({ !pendingIDs.contains($0.id) }) else { throw SyncError.revisionConflict }
        let records = try await replica.records(accountID: accountID)
        let revisions = Dictionary(records.map { ($0.mutation.identity, $0.revision) },
                                   uniquingKeysWith: max)
        let writer = EncryptedSyncWriter(cipher: cipher, keys: keys, local: replica)
        for credential in credentials {
            let identity = SyncRecordIdentity(accountID: accountID, collection: "credentials",
                                              recordID: credential.id)
            var plaintext = try JSONEncoder().encode(CloudCredentialPayload(credential))
            defer { plaintext.resetBytes(in: 0..<plaintext.count) }
            let request = SyncWriteRequest(identity: identity, expectedRevision: revisions[identity] ?? 0,
                                           plaintext: plaintext)
            _ = try await writer.enqueue(request)
        }
        try await restore()
    }

    private func project(_ mutation: SyncMutation, into current: inout [UUID: Credential], key: Data) throws {
        guard mutation.identity.accountID == accountID else { throw SyncError.accountMismatch }
        var plaintext = try cipher.decrypt(mutation, rootKey: key)
        defer { plaintext.resetBytes(in: 0..<plaintext.count) }
        if mutation.isDeleted {
            current.removeValue(forKey: mutation.identity.recordID)
            return
        }
        guard let payload = try? JSONDecoder().decode(CloudCredentialPayload.self, from: plaintext),
              payload.id == mutation.identity.recordID,
              ["http", "https"].contains(payload.origin.scheme), !payload.origin.host.isEmpty
        else { throw SyncError.invalidResponse }
        var credential = payload.credential
        if let existing = current[payload.id] {
            credential.useCount = max(existing.useCount, credential.useCount)
            credential.lastUsedAt = [existing.lastUsedAt, credential.lastUsedAt].compactMap { $0 }.max()
        }
        current[payload.id] = credential
    }
}
