import Foundation
import RedentKit

/// The one place a `BrowserAction` becomes a change to the window. Menus,
/// gestures and the Command Bar all arrive here.
extension BrowserModel {
    public func showCommands() {
        showsCommandBar = true
        refreshCommandContext()
        commandBar.query = ""
        // Another window may have saved an app since this one last looked.
        Task { await reloadWebApps() }
    }

    /// ⌘K opens the bar, and ⌘K again puts it away.
    public func toggleCommands() {
        if showsCommandBar { dismissCommands() } else { showCommands() }
    }

    public func dismissCommands() {
        showsCommandBar = false
        commandBar.close()
    }

    public func execute(_ action: BrowserAction) {
        dismissCommands()
        do {
            try route(action)
            address.finishEditing()
            address.sync(with: selectedTab)
        } catch {
            actionError = "This action is no longer available. The workspace was not changed."
        }
    }

    private func route(_ action: BrowserAction) throws {
        if try routeWorkspace(action) { return }
        if try routeWindow(action) { return }
        routePage(action)
    }

    private func routePage(_ action: BrowserAction) {
        switch action {
        case .goBack: goBack()
        case .goForward: goForward()
        case .reloadPage: reloadPage()
        case .hardReload: reloadIgnoringCache()
        case .zoomIn: zoomIn()
        case .zoomOut: zoomOut()
        case .resetZoom: resetZoom()
        case .bookmarkPage: Task { await toggleBookmark() }
        case .findOnPage: showFindBar()
        case .printPage: printPage()
        case .toggleReader: toggleReader()
        case .toggleMute: toggleMute()
        case .showScreen(let screen): sheet = SheetRoute(screen)
        default: return
        }
    }
}
