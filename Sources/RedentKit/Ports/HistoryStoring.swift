import Foundation

/// The user's browsing history.
public protocol HistoryStoring: Sendable {
    /// Records a visit, merging into an existing row for the same URL.
    func record(url: URL, title: String, at date: Date) async
    /// Best matches for a partial address-bar query, highest frecency first.
    func search(_ query: String, limit: Int) async -> [HistoryEntry]
    func recent(limit: Int) async -> [HistoryEntry]
    /// Most-visited sites, for the new-tab grid.
    func mostVisited(limit: Int) async -> [HistoryEntry]
    func merge(_ entries: [HistoryEntry]) async
    func delete(_ id: UUID) async
    func clearAll() async
    func record(_ visit: HistoryVisit) async
    func query(_ request: HistoryQuery) async -> [HistoryEntry]
    func clear(domain: String, containerID: UUID?) async
}

public extension HistoryStoring {
    /// Records an event while preserving compatibility with aggregate-only stores.
    func record(_ visit: HistoryVisit) async {
        await record(url: visit.url, title: visit.title, at: visit.date)
    }

    /// Queries contextual history when supported; old stores use address search.
    func query(_ request: HistoryQuery) async -> [HistoryEntry] {
        if request.text.isEmpty {
            return await recent(limit: request.limit)
        }
        return await search(request.text, limit: request.limit)
    }

    /// Deletes contextual visits for a domain and optional Container.
    func clear(domain: String, containerID: UUID?) async {}
}

/// Saved pages and the favorites subset shown on the new-tab page.
///
/// Bookmarks belong to a Space. Every read takes the Space to read from;
/// `nil` means every Space, which only the manager's "All Spaces" view wants.
public protocol BookmarkStoring: Sendable {
    func all(in spaceID: UUID?) async -> [Bookmark]
    func favorites(in spaceID: UUID?) async -> [Bookmark]
    func search(_ query: String, in spaceID: UUID?, limit: Int) async -> [Bookmark]
    func bookmark(for url: URL, in spaceID: UUID?) async -> Bookmark?
    func save(_ bookmark: Bookmark) async
    /// Adds anything not already present, matched on URL within its Space.
    /// - Returns: how many were new.
    @discardableResult
    func merge(_ bookmarks: [Bookmark]) async -> Int
    func delete(_ id: UUID) async
    func folders(in spaceID: UUID?) async -> [BookmarkFolder]
    func saveFolder(_ folder: BookmarkFolder) async
    func deleteFolder(_ folder: BookmarkFolder) async
}

public extension BookmarkStoring {
    func folders(in spaceID: UUID?) async -> [BookmarkFolder] { [] }
    func saveFolder(_ folder: BookmarkFolder) async {}
    func deleteFolder(_ folder: BookmarkFolder) async {}
}
