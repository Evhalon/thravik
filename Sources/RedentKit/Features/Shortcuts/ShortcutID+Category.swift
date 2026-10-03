import Foundation

extension ShortcutID {
    public var category: ShortcutCategory {
        switch self {
        case .settings, .commandBar, .undoBrowserAction, .newWindow, .newPrivateWindow:
            .general
        case .newTab, .newPrivateTab, .closeTab, .reopenClosedTab, .nextTab, .previousTab,
             .lastActiveTab, .selectTabRight, .selectTabLeft, .pinTab, .duplicateTab,
             .closeOtherTabs, .muteTab:
            .tabs
        case .reload, .hardReload, .stopLoading, .goBack, .goForward, .goHome, .openLocation,
             .copyURL, .pasteAndGo, .print, .fillLogin:
            .page
        case .findOnPage, .findNext, .findPrevious, .closeFind:
            .find
        case .toggleTabLayout, .toggleSidebar, .toggleTabStrip, .showBookmarksBar, .focusMode,
             .toggleReader, .floatVideo, .zoomIn, .zoomOut, .zoomReset, .splitView, .addPane,
             .switchPane:
            .view
        case .bookmarkPage, .showBookmarks, .showDownloads, .showHistory, .showTimeline,
             .showSitePrivacy, .showTabGroups, .toggleDevTools, .toggleConsole:
            .library
        }
    }

    public static func ids(in category: ShortcutCategory) -> [ShortcutID] {
        allCases.filter { $0.category == category }
    }
}
