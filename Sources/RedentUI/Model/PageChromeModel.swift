import Foundation
import Observation

/// Chrome state that belongs to the page rather than to the window: the find
/// bar, the bookmark star, and the requests to move the caret.
///
/// Split out of `BrowserModel` so the window model keeps one responsibility
/// per stored property rather than growing a field per control.
@MainActor @Observable
public final class PageChromeModel {
    /// Whether the address currently on screen is already bookmarked. Kept
    /// here so ⌘D and the star in the toolbar can never disagree.
    public var isBookmarked = false

    public var isFindBarVisible = false
    public var findQuery = ""
    /// The last search matched nothing — the field turns red rather than
    /// silently doing nothing.
    public var findFailed = false
    /// Bumped to ask the find field for first responder, including when the
    /// bar is already open and ⌘F is pressed again.
    public var findFocusEpoch: UInt = 0
    /// Bumped to send the caret to the address bar (⌘L).
    public var addressFocusEpoch: UInt = 0

    public init() {}

    public func focusAddress() { addressFocusEpoch &+= 1 }

    public func showFindBar() {
        isFindBarVisible = true
        findFocusEpoch &+= 1
    }

    public func hideFindBar() {
        isFindBarVisible = false
        findFailed = false
    }
}
