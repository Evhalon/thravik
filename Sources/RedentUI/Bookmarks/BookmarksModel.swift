import Foundation
import Observation
import RedentKit

/// Backs the bookmarks manager: the list, the search box, and edits.
///
/// Bookmarks belong to a Space, so the manager shows the Space you are in and
/// offers the rest of them behind a toggle — nothing is ever unreachable.
@MainActor @Observable
public final class BookmarksModel {
    public private(set) var all: [Bookmark] = []
    public var query: String = ""
    public var selectedFolder: String?
    public var showsEverySpace = false { didSet { Task { await load() } } }

    public let spaces: [BrowserSpace]
    private let spaceID: UUID?
    private let store: any BookmarkStoring

    public init(store: any BookmarkStoring, spaces: [BrowserSpace], spaceID: UUID?) {
        self.store = store
        self.spaces = spaces
        self.spaceID = spaceID
    }

    public var currentSpaceName: String { name(ofSpace: spaceID) }

    public func name(ofSpace id: UUID?) -> String {
        spaces.first { $0.id == id }?.name ?? "No Space"
    }

    public func load() async {
        all = await store.all(in: showsEverySpace ? nil : spaceID)
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

    @discardableResult
    public func rename(_ bookmark: Bookmark, to title: String) async -> Bool {
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return false }
        var updated = bookmark
        updated.title = title
        await store.save(updated)
        await load()
        return true
    }

    @discardableResult
    public func changeAddress(_ bookmark: Bookmark, to address: String) async -> Bool {
        let address = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: address),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              url.host != nil
        else { return false }
        var updated = bookmark
        updated.url = url
        await store.save(updated)
        await load()
        return true
    }

    /// Moves a saved page to another Space. The page itself is untouched: only
    /// which profile's manager and address bar will offer it changes.
    public func move(_ bookmark: Bookmark, to destination: UUID) async {
        guard bookmark.spaceID != destination else { return }
        var updated = bookmark
        updated.spaceID = destination
        await store.save(updated)
        await load()
    }

    public func delete(_ bookmark: Bookmark) async {
        await store.delete(bookmark.id)
        await load()
    }
}
