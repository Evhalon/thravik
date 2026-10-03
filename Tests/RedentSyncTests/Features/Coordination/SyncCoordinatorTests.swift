import Foundation
import Testing
import RedentKit
@testable import RedentSync

struct SyncCoordinatorTests {
    private func session(_ account: UUID) -> AccountSession {
        AccountSession(accountID: account, accessToken: "a", refreshToken: "r", expiresAt: .distantFuture)
    }

    @Test func failedUploadPreservesMutationAndPullCommitsFirst() async throws {
        let account = UUID()
        let local = SyncLocalFake(account: account)
        let transport = SyncTransportFake(fails: true)
        let coordinator = SyncCoordinator(transport: transport, local: local)
        await #expect(throws: SyncError.revisionConflict) {
            try await coordinator.synchronize(session: session(account))
        }
        #expect(await local.pending(accountID: account, limit: 100).count == 1)
        #expect(await local.applied)
    }

    @Test func successfulUploadAcknowledgesExactlyOnce() async throws {
        let account = UUID()
        let local = SyncLocalFake(account: account)
        let coordinator = SyncCoordinator(transport: SyncTransportFake(), local: local)
        let result = try await coordinator.synchronize(session: session(account))
        #expect(result.uploaded == 1)
        #expect(!result.hasMore)
        #expect(await local.pending(accountID: account, limit: 100).isEmpty)
        let next = try await coordinator.synchronize(session: session(account))
        #expect(next.uploaded == 0)
    }

    @Test func mismatchedReceiptCannotRemovePendingMutation() async throws {
        let account = UUID()
        let local = SyncLocalFake(account: account)
        let coordinator = SyncCoordinator(transport: SyncTransportFake(badReceipt: true), local: local)
        await #expect(throws: SyncError.invalidResponse) {
            try await coordinator.synchronize(session: session(account))
        }
        #expect(await local.pending(accountID: account, limit: 100).count == 1)
    }
}

private struct SyncTransportFake: SyncTransporting {
    var fails = false
    var badReceipt = false
    func push(_ mutation: SyncMutation, session: AccountSession) async throws -> SyncRemoteRecord {
        if fails { throw SyncError.revisionConflict }
        return SyncRemoteRecord(mutation: mutation, revision: badReceipt ? 10 : 1, cursor: 1)
    }
    func pull(after cursor: Int64, session: AccountSession) async throws -> SyncPage {
        SyncPage(records: [], nextCursor: cursor, hasMore: false)
    }
}

private actor SyncLocalFake: AuthenticatedSyncStoring {
    var outbox: [SyncMutation]
    var applied = false
    init(account: UUID) {
        outbox = [SyncMutation(identity: SyncRecordIdentity(accountID: account, collection: "spaces", recordID: UUID()),
                               expectedRevision: 0, encryptedPayload: Data(repeating: 1, count: 40))]
    }
    func enqueue(_ mutation: SyncMutation) { outbox.append(mutation) }
    func pending(accountID: UUID, limit: Int) -> [SyncMutation] { Array(outbox.prefix(limit)) }
    func acknowledge(_ record: SyncRemoteRecord) { outbox.removeAll { $0.id == record.mutation.id } }
    func cursor(accountID: UUID) -> Int64 { 0 }
    func apply(_ page: SyncPage, accountID: UUID) { applied = true }
    func records(accountID: UUID) -> [SyncRemoteRecord] { [] }
}
