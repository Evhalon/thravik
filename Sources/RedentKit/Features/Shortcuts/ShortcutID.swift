import Foundation

/// Commands whose menu key can be rebound. Numbered tab and Space keys stay fixed.
public enum ShortcutID: String, Codable, Hashable, Sendable, CaseIterable, Identifiable {
    case settings
    case commandBar
    case reload
    case undoBrowserAction
    case toggleTabLayout
    case toggleSidebar
    case newWindow
    case newPrivateWindow
    case newTab
    case newPrivateTab
    case closeTab
    case reopenClosedTab
    case findOnPage
    case findNext
    case findPrevious
    case closeFind
    case fillLogin
    case openLocation
    case copyURL
    case pasteAndGo
    case print
    case toggleTabStrip
    case showBookmarksBar
    case focusMode
    case toggleReader
    case floatVideo
    case zoomIn
    case zoomOut
    case zoomReset
    case splitView
    case addPane
    case switchPane
    case nextTab
    case previousTab
    case lastActiveTab
    case selectTabRight
    case selectTabLeft
    case pinTab
    case duplicateTab
    case closeOtherTabs
    case muteTab
    case goBack
    case goForward
    case hardReload
    case stopLoading
    case goHome
    case showHistory
    case bookmarkPage
    case showBookmarks
    case showDownloads
    case showTimeline
    case showSitePrivacy
    case toggleDevTools
    case toggleConsole
    case showTabGroups

    public var id: String { rawValue }
}
