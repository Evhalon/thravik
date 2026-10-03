import Foundation
import Observation
import RedentKit

/// Live chips for the current Space's bookmarks bar.
@MainActor @Observable
public final class BookmarksBarModel {
    public private(set) var items: [BookmarksBarItem] = []
    /// Measured once per load, so resizing the window only re-plans.
    public private(set) var itemWidths: [Double] = []

    private let store: any BookmarkStoring
    private var spaceID: UUID?

    public init(store: any BookmarkStoring) {
        self.store = store
    }

    public func load(in spaceID: UUID?) async {
        self.spaceID = spaceID
        guard let spaceID else { return show([]) }
        async let bookmarks = store.all(in: spaceID)
        async let folders = store.folders(in: spaceID)
        let pages = await bookmarks
        let saved = await folders
        guard !Task.isCancelled, self.spaceID == spaceID else { return }
        show(BookmarksBarCatalog.items(bookmarks: pages, folders: saved, spaceID: spaceID))
    }

    public func delete(_ bookmark: Bookmark) async {
        await store.delete(bookmark.id)
        await load(in: spaceID)
    }

    /// Removes the folder, everything filed anywhere beneath it, and its nested folders.
    public func deleteFolder(_ folder: BookmarkFolder) async {
        guard let spaceID else { return }
        let pages = await store.all(in: spaceID).filter {
            BookmarksBarCatalog.barFolderPath(containing: $0.folderPath) == folder.path
        }
        for page in pages { await store.delete(page.id) }
        for saved in await store.folders(in: spaceID) where saved.path.starts(with: folder.path) {
            await store.deleteFolder(saved)
        }
        await load(in: spaceID)
    }

    @discardableResult
    public func update(_ bookmark: Bookmark, title: String, address: String) async -> Bool {
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty, let url = BookmarksModel.validWebURL(address) else { return false }
        var updated = bookmark
        updated.title = title
        updated.url = url
        await store.save(updated)
        await load(in: spaceID)
        return true
    }

    private func show(_ next: [BookmarksBarItem]) {
        items = next
        itemWidths = next.map(BookmarksBarChipMetrics.width(of:))
    }
}
