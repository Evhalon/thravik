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
    /// The current site's cookies, storage, and permissions.
    case siteData
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
    /// Lays the page's article over it, or takes it away.
    case toggleReader
    case toggleMute
    case showScreen(BrowserScreen)
    case duplicateTab(UUID)
    /// Closes several tabs as one reversible operation.
    case closeTabs(Set<UUID>)
    case reloadAllTabs
    /// Reloads past the cache.
    case hardReload
    case zoomIn
    case zoomOut
    case resetZoom
    case toggleFullScreen
    case moveTabToGroup(tabID: UUID, groupID: UUID)
    case newWindow
    case newPrivateWindow
    case focusWindow(UUID)
    case closeWindow
    /// Hands a tab to another window. Nil opens a new window for it.
    case moveTabToWindow(tabID: UUID, windowID: UUID?)
    /// Remembers the current site as a web app.
    case saveWebApp
    case openWebApp(UUID)
    case removeWebApp(UUID)
}
