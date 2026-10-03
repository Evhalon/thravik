import Foundation

/// Top-level bar chips for one Space: loose pages plus first-rank folders.
public enum BookmarksBarCatalog {
    public static let importedRoot = "Bookmarks Bar"
    public static let excludedRoots: Set<String> = ["Other Bookmarks", "Synced"]

    public static func items(
        bookmarks: [Bookmark],
        folders: [BookmarkFolder],
        spaceID: UUID?
    ) -> [BookmarksBarItem] {
        guard let spaceID else { return [] }
        let pages = bookmarks.filter { $0.spaceID == spaceID }
        let saved = folders.filter { $0.spaceID == spaceID }
        let topPages = pages.filter { isTopLevel($0.folderPath) }.sorted { $0.addedAt > $1.addedAt }
        return topPages.map(BookmarksBarItem.page) + barFolders(from: pages, saved: saved, spaceID: spaceID)
    }

    public static func isTopLevel(_ path: [String]) -> Bool {
        path.isEmpty || path == [importedRoot]
    }

    /// The bar chip a path lives under: native `Work/…`, or Chrome's
    /// `Bookmarks Bar / Work / …`. The import root itself is not a chip.
    public static func barFolderPath(containing path: [String]) -> [String]? {
        guard let root = path.first else { return nil }
        if root == importedRoot { return path.count >= 2 ? Array(path.prefix(2)) : nil }
        return excludedRoots.contains(root) ? nil : [root]
    }

    private static func barFolders(
        from pages: [Bookmark],
        saved: [BookmarkFolder],
        spaceID: UUID
    ) -> [BookmarksBarItem] {
        var children: [[String]: [Bookmark]] = [:]
        for path in saved.compactMap({ barFolderPath(containing: $0.path) }) where children[path] == nil {
            children[path] = []
        }
        for page in pages {
            guard let path = barFolderPath(containing: page.folderPath) else { continue }
            children[path, default: []].append(page)
        }
        let records = Dictionary(saved.map { ($0.path, $0) }, uniquingKeysWith: { first, _ in first })
        return children.keys.sorted { $0.joined(separator: "/") < $1.joined(separator: "/") }.map { path in
            let record = records[path] ?? BookmarkFolder(path: path, spaceID: spaceID)
            let pages = (children[path] ?? []).sorted { $0.addedAt > $1.addedAt }
            return .folder(record, bookmarks: pages)
        }
    }
}
