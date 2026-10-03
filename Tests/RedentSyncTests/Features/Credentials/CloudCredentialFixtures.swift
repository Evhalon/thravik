import Foundation
import RedentKit
import RedentSync

actor CloudCredentialFixtures: CredentialSnapshotStoring, AuthenticatedSyncStoring, SyncKeyStoring,
                              AccountSessionStoring, SyncTransporting {
    let accountID = UUID()
    var credentials: [Credential] = []
    var mutations: [SyncMutation] = []
    var remote: [SyncRemoteRecord] = []
    var incoming: [SyncRemoteRecord] = []
    func setIncoming(_ records: [SyncRemoteRecord]) { incoming = records }
    var failSave = false
    var mismatch = false
    func setFailSave(_ value: Bool) { failSave = value }
    func setMismatch() { mismatch = true }
    func credentials(for origin: Origin) -> [Credential] { credentials.filter { $0.origin.matches(origin) } }
    func allCredentials() -> [Credential] { credentials }
    func applySnapshot(_ snapshot: [Credential]) throws {
        if failSave { throw SyncError.unavailable }
        credentials = snapshot
    }
    func save(_ credential: Credential) throws {
        if failSave { throw SyncError.unavailable }
        credentials.removeAll { $0.id == credential.id }
        credentials.append(credential)
    }
    func delete(_ id: UUID) { credentials.removeAll { $0.id == id } }
    func markUsed(_ id: UUID) {}
    func enqueue(_ mutation: SyncMutation) { mutations.append(mutation) }
    func pending(accountID: UUID, limit: Int) -> [SyncMutation] { Array(mutations.prefix(limit)) }
    func replacePending(_ mutation: SyncMutation, with replacement: SyncMutation?) throws {
        guard let index = mutations.firstIndex(of: mutation) else { throw SyncError.mutationCollision }
        if let replacement { mutations[index] = replacement } else { mutations.remove(at: index) }
    }
    func records(accountID: UUID) -> [SyncRemoteRecord] { remote }
    func cursor(accountID: UUID) -> Int64 { 0 }
    func apply(_ page: SyncPage, accountID: UUID) { remote = page.records }
    func acknowledge(_ record: SyncRemoteRecord) {
        mutations.removeAll { $0.id == record.mutation.id }
        remote.removeAll { $0.mutation.identity == record.mutation.identity }
        remote.append(record)
    }
    func load(accountID: UUID) -> Data? { Data(repeating: 7, count: 32) }
    func save(_ key: Data, accountID: UUID) {}
    func delete(accountID: UUID) {}
    func load() -> AccountSession? {
        AccountSession(accountID: mismatch ? UUID() : accountID, accessToken: "test",
                       refreshToken: "test", expiresAt: .distantFuture)
    }
    func save(_ session: AccountSession) {}
    func clear() {}
    func push(_ mutation: SyncMutation, session: AccountSession) throws -> SyncRemoteRecord {
        if let existing = remote.first(where: { $0.mutation.identity == mutation.identity }),
           existing.revision != mutation.expectedRevision { throw SyncError.revisionConflict }
        return SyncRemoteRecord(mutation: mutation, revision: mutation.expectedRevision + 1, cursor: 1)
    }
    func pull(after cursor: Int64, session: AccountSession) -> SyncPage {
        SyncPage(records: incoming, nextCursor: incoming.last?.cursor ?? 0, hasMore: false)
    }
    func store() -> CloudCredentialStore {
        CloudCredentialStore(configuration: .init(accountID: accountID, local: self,
            services: .init(replica: self, keys: self, transport: self, sessions: self)))
    }
}
