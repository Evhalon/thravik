import Foundation
import RedentKit

/// Chrome's DevTools, docked under the page in front of the user.
extension BrowserModel {
    var canToggleDevTools: Bool { selectedTab != nil }
    var isShowingDevTools: Bool { selectedTab.map { tabs.isShowingDevTools($0.id) } ?? false }

    func toggleDevTools() {
        guard let id = selectedTab?.id else { return }
        tabs.toggleDevTools(id)
    }

    func toggleConsole() {
        guard let id = selectedTab?.id else { return }
        tabs.toggleConsole(id)
    }
}
