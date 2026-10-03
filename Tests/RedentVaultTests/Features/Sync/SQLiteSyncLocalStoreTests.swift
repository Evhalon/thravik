import Foundation
import Testing
import RedentKit
@testable import RedentVault

struct SQLiteSyncLocalStoreTests {
    private func mutation(account: UUID, revision: Int64 = 0) -> SyncMutation {
        SyncMutation(identity: SyncRecordIdentity(accountID: account, collection: "workspace", recordID: UUID()),
                     expectedRevision: revision, encryptedPayload: Data(repeating: 42, count: 40))
    }

    @Test func durableOutboxIsAccountScopedAndIdempotent() async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("sync.sqlite")
        let account = UUID()
        let other = UUID()
        let store = SQLiteSyncLocalStore(fileURL: url)
        let item = mutation(account: account)
        try await store.enqueue(item)
        try await store.enqueue(item)
        try await store.enqueue(mutation(account: other))
        let reopened = SQLiteSyncLocalStore(fileURL: url)
        #expect(try await reopened.pending(accountID: account, limit: 100) == [item])
        let collision = SyncMutation(id: item.id, identity: item.identity, expectedRevision: 1,
                                     encryptedPayload: item.encryptedPayload)
        await #expect(throws: SyncError.mutationCollision) { try await store.enqueue(collision) }
    }

    @Test func uploadDoesNotSkipUnseenChangesAndBadPageCannotAdvanceCursor() async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let store = SQLiteSyncLocalStore(fileURL: folder.appendingPathComponent("sync.sqlite"))
        let account = UUID()
        let item = mutation(account: account)
        try await store.enqueue(item)
        let accepted = SyncRemoteRecord(mutation: item, revision: 1, cursor: 10)
        try await store.acknowledge(accepted)
        #expect(try await store.cursor(accountID: account) == 0)
        let earlier = SyncRemoteRecord(mutation: mutation(account: account), revision: 1, cursor: 9)
        try await store.apply(SyncPage(records: [earlier, accepted], nextCursor: 10, hasMore: false), accountID: account)
        #expect(try await store.cursor(accountID: account) == 10)
        let foreign = SyncRemoteRecord(mutation: mutation(account: UUID()), revision: 1, cursor: 11)
        await #expect(throws: SyncError.accountMismatch) {
            try await store.apply(SyncPage(records: [foreign], nextCursor: 11, hasMore: false), accountID: account)
        }
        #expect(try await store.cursor(accountID: account) == 10)
        #expect(try await store.records(accountID: account).count == 2)
    }

    @Test func remoteUpdatePreservesPendingConflict() async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let store = SQLiteSyncLocalStore(fileURL: folder.appendingPathComponent("sync.sqlite"))
        let account = UUID()
        let item = mutation(account: account)
        try await store.enqueue(item)
        let remoteMutation = SyncMutation(identity: item.identity, expectedRevision: 0,
                                          encryptedPayload: Data(repeating: 20, count: 40), isDeleted: true)
        let remote = SyncRemoteRecord(mutation: remoteMutation, revision: 1, cursor: 1)
        try await store.apply(SyncPage(records: [remote], nextCursor: 1, hasMore: false), accountID: account)
        #expect(try await store.pending(accountID: account, limit: 100) == [item])
        #expect(try await store.records(accountID: account) == [remote])
    }
}
