import Foundation
import RedentKit

/// Modal destinations reachable from the chrome.
public enum SheetRoute: String, Identifiable, Sendable {
    case settings, passwords, authenticator, importAuthenticator, importBrowser
    case bookmarks, history, downloads, spaces, groups, sitePrivacy, timeline
    /// The one-time offer to become the system's default browser.
    case defaultBrowser
    public var id: String { rawValue }

    /// The sheet that serves a screen the domain asked for.
    public init(_ screen: BrowserScreen) {
        switch screen {
        case .downloads: self = .downloads
        case .bookmarks: self = .bookmarks
        case .history: self = .history
        case .passwords: self = .passwords
        case .settings: self = .settings
        }
    }
}
