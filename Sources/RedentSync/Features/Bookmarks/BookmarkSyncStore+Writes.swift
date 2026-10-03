import Foundation
import RedentKit

extension BookmarkSyncStore {
    public func all(in spaceID: UUID?) async -> [Bookmark] { await bookmarks.all(in: spaceID) }
    public func favorites(in spaceID: UUID?) async -> [Bookmark] { await bookmarks.favorites(in: spaceID) }
    public func search(_ query: String, in spaceID: UUID?, limit: Int) async -> [Bookmark] {
        await bookmarks.search(query, in: spaceID, limit: limit)
    }
    public func bookmark(for url: URL, in spaceID: UUID?) async -> Bookmark? {
        await bookmarks.bookmark(for: url, in: spaceID)
    }
    public func folders(in spaceID: UUID?) async -> [BookmarkFolder] { await bookmarks.folders(in: spaceID) }

    public func save(_ bookmark: Bookmark) async {
        await beginWrite()
        defer { endWrite() }
        if await enqueue(bookmark, collection: "bookmarks", deleted: false) { await bookmarks.save(bookmark) }
    }

    @discardableResult
    public func merge(_ values: [Bookmark]) async -> Int {
        await beginWrite()
        defer { endWrite() }
        let existing = await bookmarks.all(in: nil)
        var existingKeys = Set(existing.map { ($0.spaceID?.uuidString ?? "") + "|" + BookmarkKey.normalized($0.url) })
        var accepted: [Bookmark] = []
        for value in values where !existingKeys.contains((value.spaceID?.uuidString ?? "") + "|" + BookmarkKey.normalized(value.url)) {
            if await enqueue(value, collection: "bookmarks", deleted: false) {
                accepted.append(value)
                existingKeys.insert((value.spaceID?.uuidString ?? "") + "|" + BookmarkKey.normalized(value.url))
            }
        }
        return await bookmarks.merge(accepted)
    }

    public func delete(_ id: UUID) async {
        await beginWrite()
        defer { endWrite() }
        let value = await bookmarks.all(in: nil).first { $0.id == id }
        if let value, await enqueue(value, collection: "bookmarks", deleted: true) { await bookmarks.delete(id) }
    }

    public func saveFolder(_ folder: BookmarkFolder) async {
        await beginWrite()
        defer { endWrite() }
        if await enqueue(folder, collection: "bookmark_folders", deleted: false) { await bookmarks.saveFolder(folder) }
    }

    public func deleteFolder(_ folder: BookmarkFolder) async {
        await beginWrite()
        defer { endWrite() }
        if await enqueue(folder, collection: "bookmark_folders", deleted: true) { await bookmarks.deleteFolder(folder) }
    }

    private func enqueue<T: Codable & Sendable>(_ value: T, collection: String, deleted: Bool) async -> Bool {
        guard var data = try? encode(value), var rootKey = try? await dependencies.keys.load(accountID: accountID) else {
            writeError = .unavailable; return false
        }
        defer { data.resetBytes(in: 0..<data.count) }
        defer { rootKey.resetBytes(in: 0..<rootKey.count) }
        guard let id = recordID(value),
              let revision = try? await revision(collection: collection, id: id) else {
            writeError = .unavailable; return false
        }
        let identity = SyncRecordIdentity(accountID: accountID, collection: collection, recordID: id)
        let request = SyncWriteRequest(identity: identity, expectedRevision: revision,
                                       plaintext: data, isDeleted: deleted)
        guard let mutation = try? cipher.encrypt(request, rootKey: rootKey) else {
            writeError = .unavailable; return false
        }
        do {
            let pending = try await dependencies.replica.pending(accountID: accountID, limit: 10_000)
            if let queued = pending.first(where: { $0.identity == identity }) {
                try await dependencies.replica.replacePending(queued, with: mutation)
            } else {
                guard pending.count < 10_000 else { throw SyncError.quotaExceeded }
                try await dependencies.replica.enqueue(mutation)
            }
            writeError = nil
            return true
        } catch {
            writeError = (error as? SyncError) ?? .unavailable
            return false
        }
    }

    private func revision(collection: String, id: UUID) async throws -> Int64 {
        let identity = SyncRecordIdentity(accountID: accountID, collection: collection, recordID: id)
        return try await dependencies.replica.records(accountID: accountID)
            .first { $0.mutation.identity == identity }?.revision ?? 0
    }

    private func recordID<T>(_ value: T) -> UUID? {
        if let page = value as? Bookmark { return page.id }
        if let folder = value as? BookmarkFolder { return folder.id }
        return nil
    }

    private func encode<T: Encodable>(_ value: T) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(value)
    }
}
