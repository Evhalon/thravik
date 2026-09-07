import Foundation

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
}
