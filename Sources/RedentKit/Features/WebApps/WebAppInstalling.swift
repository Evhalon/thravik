import Foundation

/// Turns a saved web app into an app of its own in the user's Applications
/// folder: its own name, the site's icon, a place in the Dock and Spotlight.
public protocol WebAppInstalling: Sendable {
    /// Writes, or rewrites, the app's bundle.
    func install(_ app: WebApp) async throws
    /// Starts the app's Dock presence, installing its bundle first if missing.
    func launch(_ app: WebApp) async
    func uninstall(_ app: WebApp) async
}
