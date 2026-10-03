import Foundation
import RedentKit

/// Routes bookmark operations to the local profile or an account-scoped projection.
public actor BookmarkStorageRouter: BookmarkStoring {
    private let local: any BookmarkStoring
    private var generation = UUID()
    private var accountStore: (any BookmarkStoring)?

    public init(local: any BookmarkStoring) { self.local = local }

    public func resetAccountSelection(generation: UUID) {
        self.generation = generation
        accountStore = nil
    }

    @discardableResult
    public func selectAccountStore(_ store: (any BookmarkStoring)?, generation: UUID? = nil) -> Bool {
        if let generation, generation != self.generation { return false }
        accountStore = store
        return true
    }

    public func all(in spaceID: UUID?) async -> [Bookmark] { await current().all(in: spaceID) }
    public func favorites(in spaceID: UUID?) async -> [Bookmark] { await current().favorites(in: spaceID) }
    public func search(_ query: String, in spaceID: UUID?, limit: Int) async -> [Bookmark] {
        await current().search(query, in: spaceID, limit: limit)
    }
    public func bookmark(for url: URL, in spaceID: UUID?) async -> Bookmark? {
        await current().bookmark(for: url, in: spaceID)
    }
    public func save(_ bookmark: Bookmark) async { await current().save(bookmark) }
    public func merge(_ bookmarks: [Bookmark]) async -> Int { await current().merge(bookmarks) }
    public func delete(_ id: UUID) async { await current().delete(id) }
    public func folders(in spaceID: UUID?) async -> [BookmarkFolder] { await current().folders(in: spaceID) }
    public func saveFolder(_ folder: BookmarkFolder) async { await current().saveFolder(folder) }
    public func deleteFolder(_ folder: BookmarkFolder) async { await current().deleteFolder(folder) }

    private func current() -> any BookmarkStoring { accountStore ?? local }
}
