import Foundation
import RedentKit

/// Modal destinations reachable from the chrome.
public enum SheetRoute: String, Identifiable, Sendable {
    case passwords, authenticator, importAuthenticator, importBrowser
    case bookmarks, history, downloads, spaces, groups, sitePrivacy, timeline
    /// The one-time offer to become the system's default browser.
    case defaultBrowser
    public var id: String { rawValue }

    /// The sheet that serves a screen the domain asked for; nil for Settings,
    /// which is a page of its own rather than a sheet.
    public init?(_ screen: BrowserScreen) {
        switch screen {
        case .downloads: self = .downloads
        case .bookmarks: self = .bookmarks
        case .history: self = .history
        case .passwords: self = .passwords
        case .settings: return nil
        case .siteData: self = .sitePrivacy
        }
    }
}
