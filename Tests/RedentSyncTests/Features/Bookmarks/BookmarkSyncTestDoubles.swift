import Foundation
import RedentKit
@testable import RedentSync

actor BookmarkSyncTestBookmarkStore: BookmarkStoring {
    private var pages: [UUID: Bookmark] = [:]
    private var savedFolders: [UUID: BookmarkFolder] = [:]
    func all(in spaceID: UUID?) -> [Bookmark] { pages.values.filter { spaceID == nil || $0.spaceID == spaceID } }
    func favorites(in spaceID: UUID?) -> [Bookmark] { all(in: spaceID).filter(\.isFavorite) }
    func search(_ query: String, in spaceID: UUID?, limit: Int) -> [Bookmark] { Array(all(in: spaceID).prefix(limit)) }
    func bookmark(for url: URL, in spaceID: UUID?) -> Bookmark? { all(in: spaceID).first { $0.url == url } }
    func save(_ bookmark: Bookmark) { pages[bookmark.id] = bookmark }
    func merge(_ bookmarks: [Bookmark]) -> Int {
        let missing = bookmarks.filter { pages[$0.id] == nil }
        for value in missing { pages[value.id] = value }
        return missing.count
    }
    func delete(_ id: UUID) { pages[id] = nil }
    func folders(in spaceID: UUID?) async -> [BookmarkFolder] {
        savedFolders.values.filter { spaceID == nil || $0.spaceID == spaceID }
    }
    func saveFolder(_ folder: BookmarkFolder) async { savedFolders[folder.id] = folder }
    func deleteFolder(_ folder: BookmarkFolder) async { savedFolders[folder.id] = nil }
}

actor BookmarkSyncTestKeys: SyncKeyStoring {
    private let account: UUID
    private let key: Data

    init(account: UUID, key: Data) {
        self.account = account
        self.key = key
    }

    func load(accountID: UUID) async throws -> Data? { accountID == account ? key : nil }
    func save(_ key: Data, accountID: UUID) async throws {}
    func delete(accountID: UUID) async throws {}
}

actor BookmarkSyncTestDeviceKeys: SyncDeviceKeyStoring {
    private let account: UUID
    private let device: SyncDeviceSecrets
    init(account: UUID, device: SyncDeviceSecrets) { self.account = account; self.device = device }
    func load(accountID: UUID) async throws -> SyncDeviceSecrets? { accountID == account ? device : nil }
    func save(_ secrets: SyncDeviceSecrets, accountID: UUID) async throws {}
    func delete(accountID: UUID) async throws {}
}

actor BookmarkSyncTestSessions: AccountSessionStoring {
    private let session: AccountSession
    init(account: UUID) {
        session = AccountSession(accountID: account, accessToken: "access", refreshToken: "refresh",
                                 expiresAt: .distantFuture)
    }
    func load() async throws -> AccountSession? { session }
    func save(_ session: AccountSession) async throws {}
    func clear() async throws {}
}

actor BookmarkSyncTestServer: SyncTransporting {
    private var current: [SyncRecordIdentity: SyncRemoteRecord] = [:]
    private var cursor: Int64 = 0

    func push(_ mutation: SyncMutation, session: AccountSession) async throws -> SyncRemoteRecord {
        let previous = current[mutation.identity]?.revision ?? 0
        guard mutation.expectedRevision == previous else { throw SyncError.revisionConflict }
        cursor += 1
        let record = SyncRemoteRecord(mutation: mutation, revision: previous + 1, cursor: cursor)
        current[mutation.identity] = record
        return record
    }

    func pull(after requested: Int64, session: AccountSession) async throws -> SyncPage {
        let records = current.values.filter { $0.cursor > requested }.sorted { $0.cursor < $1.cursor }
        return SyncPage(records: records, nextCursor: cursor, hasMore: false)
    }
}

actor BookmarkSyncTestReplica: AuthenticatedSyncStoring {
    private var outbox: [UUID: SyncMutation] = [:]
    private var stored: [SyncRecordIdentity: SyncRemoteRecord] = [:]
    private var cursors: [UUID: Int64] = [:]

    func enqueue(_ mutation: SyncMutation) { outbox[mutation.id] = mutation }
    func replacePending(_ mutation: SyncMutation, with replacement: SyncMutation?) throws {
        guard outbox[mutation.id] == mutation else { throw SyncError.mutationCollision }
        outbox[mutation.id] = nil
        if let replacement { outbox[replacement.id] = replacement }
    }
    func pending(accountID: UUID, limit: Int) -> [SyncMutation] {
        Array(outbox.values.filter { $0.identity.accountID == accountID }.prefix(limit))
    }
    func acknowledge(_ record: SyncRemoteRecord) {
        outbox[record.mutation.id] = nil
        stored[record.mutation.identity] = record
    }
    func cursor(accountID: UUID) -> Int64 { cursorValue(accountID) }
    func apply(_ page: SyncPage, accountID: UUID) {
        for record in page.records { stored[record.mutation.identity] = record }
        cursors[accountID] = page.nextCursor
    }
    func records(accountID: UUID) -> [SyncRemoteRecord] {
        stored.values.filter { $0.mutation.identity.accountID == accountID }
    }
    private func cursorValue(_ accountID: UUID) -> Int64 { cursors[accountID, default: 0] }
}
