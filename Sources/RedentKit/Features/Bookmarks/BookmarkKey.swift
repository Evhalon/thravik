import Foundation

/// A dedupe key for bookmarks: scheme + host + path + query, trailing slash
/// and fragment ignored. The query stays in — on many sites it is what names
/// the page (`watch?v=…`, `item?id=…`) — minus tracking parameters, so two
/// links to one page from different campaigns are still one bookmark.
public enum BookmarkKey {
    public static func normalized(_ url: URL) -> String {
        let clean = TrackingParameters.stripped(url) ?? url
        let scheme = (clean.scheme ?? "").lowercased()
        let host = (clean.host() ?? "").lowercased()
        var path = clean.path
        if path.count > 1, path.hasSuffix("/") {
            path.removeLast()
        }
        let query = clean.query(percentEncoded: true).map { "?\($0)" } ?? ""
        return "\(scheme)://\(host)\(path)\(query)"
    }
}
