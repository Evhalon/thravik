import Foundation
import RedentKit

/// Finds the address the user is most likely typing, from pages they already
/// know. Candidates arrive best first, so the first one that extends the
/// typed text wins.
///
/// A bare word completes to a host (`git` → `github.com`), never to a deep
/// page: the site is the safe guess. Once the user types a slash they are
/// asking for a path, and the completion follows them into it.
enum InlineCompletionFinder {
    static func completion(for typed: String, candidates: [URL]) -> InlineCompletion? {
        guard !typed.isEmpty, !typed.contains(where: \.isWhitespace), !typed.contains("://") else { return nil }
        let needle = typed.lowercased()
        for url in candidates {
            guard let target = target(for: url, matching: needle) else { continue }
            guard target.text.count > typed.count else { return nil }
            return InlineCompletion(typed: typed, suffix: String(target.text.dropFirst(typed.count)), url: target.url)
        }
        return nil
    }

    private static func target(for url: URL, matching needle: String) -> (text: String, url: URL)? {
        guard let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https",
              let host = url.host()?.lowercased()
        else { return nil }
        let authority = host + (url.port.map { ":\($0)" } ?? "")
        let site = authority.hasPrefix("www.") ? String(authority.dropFirst(4)) : authority
        var path = needle.contains("/") ? url.path() : ""
        if path.hasSuffix("/") { path.removeLast() }
        let text = site + path
        guard text.lowercased().hasPrefix(needle),
              let target = URL(string: "\(scheme)://\(authority)\(path)")
        else { return nil }
        return (text, target)
    }
}
