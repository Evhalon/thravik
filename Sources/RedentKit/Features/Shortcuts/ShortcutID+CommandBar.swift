import Foundation

extension ShortcutID {
    /// Command Center descriptor ids that share a menu shortcut. Paste and Go is
    /// left out: its key only works while the address bar is being edited.
    public init?(commandDescriptorID: String) {
        switch commandDescriptorID {
        case "new-tab": self = .newTab
        case "close-tab": self = .closeTab
        case "reopen-tab": self = .reopenClosedTab
        case "duplicate-tab": self = .duplicateTab
        case "pin-tab": self = .pinTab
        case "close-other-tabs": self = .closeOtherTabs
        case "new-window": self = .newWindow
        case "new-private-window": self = .newPrivateWindow
        case "focus-mode": self = .focusMode
        case "sidebar": self = .toggleSidebar
        case "back": self = .goBack
        case "forward": self = .goForward
        case "reload": self = .reload
        case "hard-reload": self = .hardReload
        case "zoom-in": self = .zoomIn
        case "zoom-out": self = .zoomOut
        case "zoom-reset": self = .zoomReset
        case "bookmark": self = .bookmarkPage
        case "find": self = .findOnPage
        case "reader": self = .toggleReader
        case "mute": self = .muteTab
        case "print": self = .print
        case "downloads": self = .showDownloads
        case "bookmarks": self = .showBookmarks
        case "history": self = .showHistory
        case "settings": self = .settings
        default: return nil
        }
    }
}
