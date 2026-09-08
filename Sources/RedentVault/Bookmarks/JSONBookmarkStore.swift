import Foundation
import RedentKit

/// JSON-backed `BookmarkStoring`. A thin, `Sendable` façade over the actor
/// that holds the decoded list in memory and does the I/O off-main.
public struct JSONBookmarkStore: BookmarkStoring {
    private let store: BookmarkFileStore

    /// - Parameter fileURL: defaults to `~/Library/Application Support/Redent/bookmarks.json`.
    public init(fileURL: URL? = nil) {
        let resolvedURL = fileURL ?? RedentSupportDirectory.defaultFileURL(named: "bookmarks.json")
        store = BookmarkFileStore(fileURL: resolvedURL)
    }

    public func all(in spaceID: UUID?) async -> [Bookmark] {
        await store.all(in: spaceID)
    }

    public func favorites(in spaceID: UUID?) async -> [Bookmark] {
        await store.favorites(in: spaceID)
    }

    public func search(_ query: String, in spaceID: UUID?, limit: Int) async -> [Bookmark] {
        await store.search(query, in: spaceID, limit: limit)
    }

    public func bookmark(for url: URL, in spaceID: UUID?) async -> Bookmark? {
        await store.bookmark(for: url, in: spaceID)
    }

    public func save(_ bookmark: Bookmark) async {
        await store.save(bookmark)
    }

    @discardableResult
    public func merge(_ bookmarks: [Bookmark]) async -> Int {
        await store.merge(bookmarks)
    }

    public func delete(_ id: UUID) async {
        await store.delete(id)
    }
}
