import Foundation

/// A screen the chrome can put in front of the user. Named here rather than in
/// the UI layer so an action can ask for one without the domain knowing what a
/// sheet is.
public enum BrowserScreen: String, Hashable, Sendable, CaseIterable {
    case downloads
    case bookmarks
    case history
    case passwords
    case settings
}

/// An intent emitted by menus, gestures, and the Command Bar.
public enum BrowserAction: Hashable, Sendable {
    case newTab(URL?)
    case navigate(URL)
    case focusTab(UUID)
    case closeTab(UUID)
    case reopenLastClosed
    case pinTab(UUID, isPinned: Bool)
    case focusSpace(UUID)
    case createSpace(name: String)
    case renameSpace(id: UUID, name: String)
    case deleteSpace(UUID)
    case moveTab(tabID: UUID, spaceID: UUID)
    case goBack
    case goForward
    case toggleFocusMode
    case toggleSidebar
    case reloadPage
    /// Adds the current page to bookmarks, or removes the bookmark it has.
    case bookmarkPage
    case findOnPage
    case printPage
    case showScreen(BrowserScreen)
}
