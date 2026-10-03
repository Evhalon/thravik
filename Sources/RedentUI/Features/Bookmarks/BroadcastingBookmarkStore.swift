import Foundation
import RedentKit

extension Notification.Name {
    /// Posted on the main actor after any write through `BroadcastingBookmarkStore`.
    public static let bookmarksDidChange = Notification.Name("app.redent.bookmarksDidChange")
}

/// Announces every write, so surfaces such as the bookmarks bar in each window
/// refresh from one signal instead of each editor knowing who to tell.
public struct BroadcastingBookmarkStore: BookmarkStoring {
    private let base: any BookmarkStoring

    public init(_ base: any BookmarkStoring) {
        self.base = base
    }

    public func all(in spaceID: UUID?) async -> [Bookmark] { await base.all(in: spaceID) }
    public func favorites(in spaceID: UUID?) async -> [Bookmark] { await base.favorites(in: spaceID) }

    public func search(_ query: String, in spaceID: UUID?, limit: Int) async -> [Bookmark] {
        await base.search(query, in: spaceID, limit: limit)
    }

    public func bookmark(for url: URL, in spaceID: UUID?) async -> Bookmark? {
        await base.bookmark(for: url, in: spaceID)
    }

    public func folders(in spaceID: UUID?) async -> [BookmarkFolder] { await base.folders(in: spaceID) }

    public func save(_ bookmark: Bookmark) async {
        await base.save(bookmark)
        await Self.announce()
    }

    @discardableResult
    public func merge(_ bookmarks: [Bookmark]) async -> Int {
        let added = await base.merge(bookmarks)
        if added > 0 { await Self.announce() }
        return added
    }

    public func delete(_ id: UUID) async {
        await base.delete(id)
        await Self.announce()
    }

    public func saveFolder(_ folder: BookmarkFolder) async {
        await base.saveFolder(folder)
        await Self.announce()
    }

    public func deleteFolder(_ folder: BookmarkFolder) async {
        await base.deleteFolder(folder)
        await Self.announce()
    }

    @MainActor
    private static func announce() {
        NotificationCenter.default.post(name: .bookmarksDidChange, object: nil)
    }
}
