import Foundation

/// One chip on the bookmarks bar: a page, or a folder of pages.
public enum BookmarksBarItem: Hashable, Sendable, Identifiable {
    case page(Bookmark)
    case folder(BookmarkFolder, bookmarks: [Bookmark])

    public var id: String {
        switch self {
        case .page(let bookmark):
            "page:\(bookmark.id.uuidString)"
        case .folder(let folder, _):
            "folder:\(folder.spaceID?.uuidString ?? "")/\(folder.path.joined(separator: "/"))"
        }
    }

    public var title: String {
        switch self {
        case .page(let bookmark):
            bookmark.displayTitle
        case .folder(let folder, _):
            folder.path.last ?? folder.label
        }
    }
}
