import Foundation
import RedentKit

/// Actions that reach past this window's tabs: other windows, full screen,
/// the window's chrome, and web apps.
extension BrowserModel {
    /// - Returns: false when `action` is not a window action.
    func routeWindow(_ action: BrowserAction) throws -> Bool {
        switch action {
        case .newWindow: newWindow()
        case .newPrivateWindow: newPrivateWindow()
        case .focusWindow(let id): windowDirectory?.focus(id)
        case .closeWindow: windowDirectory?.closeCurrent()
        case .toggleFullScreen: windowDirectory?.toggleFullScreen()
        case .toggleFocusMode: toggleFocusMode()
        case .toggleSidebar: toggleSidebar()
        case .moveTabToWindow(let id, let window): try moveTab(id, toWindow: window)
        case .saveWebApp: try saveCurrentSiteAsApp()
        case .openWebApp(let id): try openWebApp(id)
        case .removeWebApp(let id): removeWebApp(id)
        default: return false
        }
        return true
    }

    /// A lone tab stays put: detaching it would leave this window empty.
    func canDetach(_ id: UUID) -> Bool {
        windowDirectory != nil
            && tabs.tabs.count > 1
            && tabs.tabs.contains { $0.id == id && $0.url != nil }
    }

    /// The page reopens at its address in the other window; the tab here
    /// closes only once that window has accepted it.
    private func moveTab(_ id: UUID, toWindow windowID: UUID?) throws {
        guard let directory = windowDirectory,
              let url = tabs.tabs.first(where: { $0.id == id })?.url,
              directory.adopt(url, into: windowID) else { throw CommandActionError.unavailable }
        tabs.close(id)
    }
}
