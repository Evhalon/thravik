import Foundation

/// Decides which addresses belong to another app rather than to a tab.
///
/// Sign-in flows hand their result back through the app's own scheme
/// (`claude://`, `zoommtg://`, `slack://`). WebKit cannot load those, so a
/// tab that tries fails silently; they have to go to Launch Services.
@MainActor
enum ExternalURLRouting {
    private static let webSchemes: Set<String> = [
        "http", "https", "about", "blob", "data", "file", "javascript"
    ]

    static func leavesBrowser(_ url: URL?) -> Bool {
        guard let scheme = url?.scheme?.lowercased(), !scheme.isEmpty else { return false }
        return !webSchemes.contains(scheme) && scheme != DevToolsFrontendScheme.scheme
    }
}
