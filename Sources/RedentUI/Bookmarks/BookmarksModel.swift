import Foundation
import Observation
import RedentKit

/// Backs the bookmarks manager: the list, the search box, and edits.
@MainActor @Observable
public final class BookmarksModel {
    public private(set) var all: [Bookmark] = []
    public var query: String = ""
    public var selectedFolder: String?

    private let store: any BookmarkStoring

    public init(store: any BookmarkStoring) {
        self.store = store
    }

    public func load() async {
        all = await store.all()
    }

    /// Folder paths present in the data, for the sidebar.
    public var folders: [String] {
        Array(Set(all.map(\.folderLabel))).sorted()
    }

    public var visible: [Bookmark] {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return all
            .filter { selectedFolder == nil || $0.folderLabel == selectedFolder }
            .filter { bookmark in
                guard !text.isEmpty else { return true }
                return bookmark.displayTitle.lowercased().contains(text)
                    || (bookmark.origin?.host.contains(text) ?? false)
            }
            .sorted { $0.addedAt > $1.addedAt }
    }

    public func toggleFavorite(_ bookmark: Bookmark) async {
        var updated = bookmark
        updated.isFavorite.toggle()
        await store.save(updated)
        await load()
    }

    public func delete(_ bookmark: Bookmark) async {
        await store.delete(bookmark.id)
        await load()
    }
}
