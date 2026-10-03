import Foundation
import Testing
import RedentKit
@testable import RedentSync

struct AuthenticatedSyncLocalStoreTests {
    @Test func tamperedPageDoesNotReachDurableCursor() async throws {
        let account = UUID()
        let key = SyncCryptography().makeRootKey()
        let keys = SyncKeyFake(key: key)
        let raw = CipherReplicaFake()
        let cipher = SyncMutationCipher()
        let local = AuthenticatedSyncLocalStore(underlying: raw, cipher: cipher, keys: keys)
        let identity = SyncRecordIdentity(accountID: account, collection: "spaces", recordID: UUID())
        let original = try cipher.encrypt(SyncWriteRequest(identity: identity, expectedRevision: 0,
                                                           plaintext: Data("space".utf8)), rootKey: key)
        let altered = SyncMutation(id: original.id, identity: identity, expectedRevision: 0,
                                   encryptedPayload: original.encryptedPayload, isDeleted: true)
        let page = SyncPage(records: [SyncRemoteRecord(mutation: altered, revision: 1, cursor: 1)],
                            nextCursor: 1, hasMore: false)
        await #expect(throws: SyncCryptoError.authenticationFailed) { try await local.apply(page, accountID: account) }
        #expect(await raw.cursor(accountID: account) == 0)
        await raw.enqueue(altered)
        await #expect(throws: SyncCryptoError.authenticationFailed) {
            try await local.pending(accountID: account, limit: 100)
        }
        let valid = SyncPage(records: [SyncRemoteRecord(mutation: original, revision: 1, cursor: 1)],
                             nextCursor: 1, hasMore: false)
        try await local.apply(valid, accountID: account)
        #expect(await raw.cursor(accountID: account) == 1)
    }
}

private actor SyncKeyFake: SyncKeyStoring {
    var key: Data?
    init(key: Data) { self.key = key }
    func load(accountID: UUID) -> Data? { key }
    func save(_ key: Data, accountID: UUID) { self.key = key }
    func delete(accountID: UUID) { key = nil }
}

private actor CipherReplicaFake: SyncLocalStoring {
    private var lastCursor: Int64 = 0
    private var outbox: [SyncMutation] = []
    func enqueue(_ mutation: SyncMutation) { outbox.append(mutation) }
    func pending(accountID: UUID, limit: Int) -> [SyncMutation] { Array(outbox.prefix(limit)) }
    func acknowledge(_ record: SyncRemoteRecord) {}
    func cursor(accountID: UUID) -> Int64 { lastCursor }
    func apply(_ page: SyncPage, accountID: UUID) { lastCursor = page.nextCursor }
    func records(accountID: UUID) -> [SyncRemoteRecord] { [] }
}
