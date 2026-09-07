import Foundation

/// Modal destinations reachable from the chrome.
public enum SheetRoute: String, Identifiable, Sendable {
    case settings, passwords, authenticator, importAuthenticator, importBrowser, bookmarks, history, spaces, groups, containers, sitePrivacy, timeline
    public var id: String { rawValue }
}
