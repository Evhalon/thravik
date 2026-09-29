import Foundation

/// The app's open windows, as one window sees them.
///
/// A window model cannot know what a window is — only the composition root
/// does — so everything that reaches past its own tabs goes through here.
@MainActor
public protocol BrowserWindowDirectory: AnyObject {
    /// Every open window, the asking one marked current.
    var windows: [CommandWindowContext] { get }
    func focus(_ id: UUID)
    func closeCurrent()
    func toggleFullScreen()
    /// Opens `url` in window `id`, or in a new window when nil.
    /// - Returns: false when the move would carry a page across the private
    ///   boundary, or the window is gone. Nothing is opened then.
    @discardableResult func adopt(_ url: URL, into id: UUID?) -> Bool
    /// Brings the app's window forward, or opens one browsing in `space` at
    /// `url` — the app's own address when nil.
    func open(_ app: WebApp, at url: URL?, in space: BrowserSpace?)
}
