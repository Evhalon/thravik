import Foundation

/// One node in Chromium's `Bookmarks` JSON tree — a folder or a leaf URL.
struct BookmarkNode: Decodable {
    let type: String
    let name: String
    let url: String?
    let dateAdded: String?
    let children: [BookmarkNode]?

    enum CodingKeys: String, CodingKey {
        case type, name, url
        case dateAdded = "date_added"
        case children
    }

    var isFolder: Bool { type == "folder" }
}

/// The top-level shape of Chromium's `Bookmarks` file.
struct BookmarksFile: Decodable {
    let roots: Roots

    struct Roots: Decodable {
        let bookmarkBar: BookmarkNode?
        let other: BookmarkNode?
        let synced: BookmarkNode?

        enum CodingKeys: String, CodingKey {
            case bookmarkBar = "bookmark_bar"
            case other, synced
        }
    }
}
