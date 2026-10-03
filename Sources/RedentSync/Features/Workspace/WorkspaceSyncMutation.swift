import Foundation
import RedentKit

struct WorkspaceSyncMutation {
    let accountID: UUID
    let replica: any AuthenticatedSyncStoring
    private let cipher = SyncMutationCipher()

    func enqueue(collection: String, recordID: UUID, plaintext: Data, rootKey: Data) async throws {
        let identity = SyncRecordIdentity(accountID: accountID, collection: collection, recordID: recordID)
        let pending = try await replica.pending(accountID: accountID, limit: 10_000)
        let existing = pending.first { $0.identity == identity }
        guard existing != nil || pending.count < 10_000 else { throw SyncError.quotaExceeded }
        let records = try await replica.records(accountID: accountID)
        let revision = records.first { $0.mutation.identity == identity }?.revision ?? 0
        let request = SyncWriteRequest(identity: identity, expectedRevision: revision, plaintext: plaintext)
        let mutation = try cipher.encrypt(request, rootKey: rootKey)
        if let existing {
            try await replica.replacePending(existing, with: mutation)
        } else {
            try await replica.enqueue(mutation)
        }
    }
}
