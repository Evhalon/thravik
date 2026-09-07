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

    public func all() async -> [Bookmark] {
        await store.all()
    }

    public func favorites() async -> [Bookmark] {
        await store.favorites()
    }

    public func search(_ query: String, limit: Int) async -> [Bookmark] {
        await store.search(query, limit: limit)
    }

    public func bookmark(for url: URL) async -> Bookmark? {
        await store.bookmark(for: url)
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
