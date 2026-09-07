import Foundation

/// A dedupe key for bookmarks: scheme + host + path, trailing slash ignored.
/// Query string and fragment are deliberately excluded — two links to the
/// same page with different tracking parameters are the same bookmark.
enum BookmarkKey {
    static func normalized(_ url: URL) -> String {
        let scheme = (url.scheme ?? "").lowercased()
        let host = (url.host() ?? "").lowercased()
        var path = url.path
        if path.count > 1, path.hasSuffix("/") {
            path.removeLast()
        }
        return "\(scheme)://\(host)\(path)"
    }
}
