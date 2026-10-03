import Foundation
import RedentKit

extension BookmarkSyncStore {
    func rebasePending(rootKey: Data) async throws {
        let records = try await dependencies.replica.records(accountID: accountID)
        let revisions = Dictionary(uniqueKeysWithValues: records.map { ($0.mutation.identity, $0.revision) })
        let pending = try await dependencies.replica.pending(accountID: accountID, limit: 10_000)
        for mutation in pending where collectionKind(mutation.identity.collection) != nil {
            let expected = revisions[mutation.identity] ?? 0
            guard mutation.expectedRevision != expected else { continue }
            var plaintext = try cipher.decrypt(mutation, rootKey: rootKey)
            defer { plaintext.resetBytes(in: 0..<plaintext.count) }
            let request = SyncWriteRequest(identity: mutation.identity, expectedRevision: expected,
                                           plaintext: plaintext, isDeleted: mutation.isDeleted)
            let replacement = try cipher.encrypt(request, rootKey: rootKey)
            try await dependencies.replica.replacePending(mutation, with: replacement)
        }
    }

    func upload(session: AccountSession) async throws {
        let pending = try await dependencies.replica.pending(accountID: accountID, limit: 10_000)
        for mutation in pending.filter({ collectionKind($0.identity.collection) != nil }).prefix(100) {
            try Task.checkCancellation()
            guard mutation.identity.accountID == accountID else { throw SyncError.accountMismatch }
            let accepted = try await dependencies.transport.push(mutation, session: session)
            guard accepted.mutation == mutation, accepted.revision == mutation.expectedRevision + 1,
                  accepted.cursor > 0 else { throw SyncError.invalidResponse }
            try await dependencies.replica.acknowledge(accepted)
        }
    }

    func hasPending() async throws -> Bool {
        try await dependencies.replica.pending(accountID: accountID, limit: 10_000)
            .contains { collectionKind($0.identity.collection) != nil }
    }
}
