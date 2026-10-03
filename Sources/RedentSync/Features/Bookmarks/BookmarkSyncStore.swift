import Foundation
import RedentKit

public actor BookmarkSyncStore: BookmarkSyncing, BookmarkStoring {
    let accountID: UUID
    let dependencies: BookmarkSyncDependencies
    let bookmarks: any BookmarkStoring
    let cipher = SyncMutationCipher()
    private var busy = false
    private var waiting: [CheckedContinuation<Void, Never>] = []
    public internal(set) var writeError: SyncError?

    public init(accountID: UUID, dependencies: BookmarkSyncDependencies, bookmarks: any BookmarkStoring) {
        self.accountID = accountID
        self.dependencies = dependencies
        self.bookmarks = bookmarks
    }

    public func synchronize() async throws -> Bool {
        try begin()
        defer { endWrite() }
        var context = try await unlocked()
        defer { context.key.resetBytes(in: 0..<context.key.count) }
        let page = try await pull(session: context.session)
        guard !page.hasMore else { return true }
        try await rebasePending(rootKey: context.key)
        try await project(rootKey: context.key)
        try await upload(session: context.session)
        let next = try await pull(session: context.session)
        try await rebasePending(rootKey: context.key)
        try await project(rootKey: context.key)
        let pending = try await hasPending()
        return next.hasMore || pending
    }

    private func begin() throws {
        guard !busy else { throw SyncError.alreadyRunning }
        busy = true
    }

    func beginWrite() async {
        if busy { await withCheckedContinuation { waiting.append($0) } }
        busy = true
    }

    func endWrite() {
        if waiting.isEmpty { busy = false } else { waiting.removeFirst().resume() }
    }

    private func unlocked() async throws -> Context {
        guard let session = try await dependencies.sessions.load(), session.accountID == accountID,
              session.expiresAt > Date(), let key = try await dependencies.keys.load(accountID: accountID),
              let device = try await dependencies.deviceKeys.load(accountID: accountID) else {
            throw SyncError.unauthorized
        }
        return Context(key: key, session: session, deviceID: device.deviceID)
    }

    private func pull(session: AccountSession) async throws -> SyncPage {
        let cursor = try await dependencies.replica.cursor(accountID: accountID)
        let page = try await dependencies.transport.pull(after: cursor, session: session)
        try Task.checkCancellation()
        try SyncPageValidation.validate(page, accountID: accountID, after: cursor)
        try await dependencies.replica.apply(page, accountID: accountID)
        return page
    }

    private func project(rootKey: Data) async throws {
        let pending = Set(try await dependencies.replica.pending(accountID: accountID, limit: 10_000)
            .filter { collectionKind($0.identity.collection) != nil }.map(\.identity))
        for record in try await dependencies.replica.records(accountID: accountID) {
            let mutation = record.mutation
            guard mutation.identity.accountID == accountID else { throw SyncError.accountMismatch }
            guard collectionKind(mutation.identity.collection) != nil else { continue }
            guard !pending.contains(mutation.identity) else { continue }
            var plaintext = try cipher.decrypt(mutation, rootKey: rootKey)
            defer { plaintext.resetBytes(in: 0..<plaintext.count) }
            try await apply(mutation, plaintext: plaintext)
        }
    }

    private func apply(_ mutation: SyncMutation, plaintext: Data) async throws {
        switch collectionKind(mutation.identity.collection) {
        case .page:
            guard let value = try? JSONDecoder().decode(Bookmark.self, from: plaintext), value.id == mutation.identity.recordID
            else { throw SyncError.invalidResponse }
            if mutation.isDeleted { await bookmarks.delete(value.id) } else { await bookmarks.save(value) }
        case .folder:
            guard let value = try? JSONDecoder().decode(BookmarkFolder.self, from: plaintext), value.id == mutation.identity.recordID
            else { throw SyncError.invalidResponse }
            if mutation.isDeleted { await bookmarks.deleteFolder(value) } else { await bookmarks.saveFolder(value) }
        case nil: break
        }
    }

    func collectionKind(_ collection: String) -> ContextCollection? {
        switch collection {
        case "bookmarks": .page
        case "bookmark_folders": .folder
        default: nil
        }
    }

    enum ContextCollection { case page, folder }
    private struct Context { var key: Data; let session: AccountSession; let deviceID: UUID }
}
