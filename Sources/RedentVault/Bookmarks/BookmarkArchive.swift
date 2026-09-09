import Foundation
import RedentKit

/// Disk representation of bookmarks and their empty folders.
struct BookmarkArchive: Codable {
    var bookmarks: [Bookmark]
    var folders: [BookmarkFolder]

    init(bookmarks: [Bookmark] = [], folders: [BookmarkFolder] = []) {
        self.bookmarks = bookmarks
        self.folders = folders
    }
}
