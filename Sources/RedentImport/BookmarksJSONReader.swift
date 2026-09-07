import Foundation
import RedentKit

/// Parses Chromium's `Bookmarks` JSON file into flat `[Bookmark]` values.
enum BookmarksJSONReader {
    /// `dateAdded` is a *string* of Chrome-epoch microseconds.
    private static func date(from dateAdded: String?) -> Date {
        guard let dateAdded, let microseconds = Int64(dateAdded) else { return .now }
        return ChromeEpoch.date(fromMicroseconds: microseconds)
    }

    static func read(from fileURL: URL) throws -> [Bookmark] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }

        let data: Data
        do {
            data = try Data(contentsOf: fileURL)
        } catch {
            throw ImportError.malformedBookmarks
        }

        let file: BookmarksFile
        do {
            file = try JSONDecoder().decode(BookmarksFile.self, from: data)
        } catch {
            throw ImportError.malformedBookmarks
        }

        var bookmarks: [Bookmark] = []
        let roots: [(BookmarkNode?, String)] = [
            (file.roots.bookmarkBar, "Bookmarks Bar"),
            (file.roots.other, "Other Bookmarks"),
            (file.roots.synced, "Synced")
        ]
        for (root, displayName) in roots {
            guard let root else { continue }
            flatten(root, path: [], rootName: displayName, isFavoriteRoot: displayName == "Bookmarks Bar", into: &bookmarks)
        }
        return bookmarks
    }

    private static func flatten(
        _ node: BookmarkNode,
        path: [String],
        rootName: String,
        isFavoriteRoot: Bool,
        into bookmarks: inout [Bookmark]
    ) {
        if node.isFolder {
            // The root node itself carries the display name; its children
            // are what actually nest under `path`.
            let childPath = path.isEmpty ? [rootName] : path + [node.name]
            for child in node.children ?? [] {
                flatten(child, path: childPath, rootName: rootName, isFavoriteRoot: isFavoriteRoot, into: &bookmarks)
            }
            return
        }

        guard let urlString = node.url, let url = URL(string: urlString) else { return }
        bookmarks.append(
            Bookmark(
                url: url,
                title: node.name,
                folderPath: path.isEmpty ? [rootName] : path,
                addedAt: date(from: node.dateAdded),
                isFavorite: isFavoriteRoot
            )
        )
    }
}
