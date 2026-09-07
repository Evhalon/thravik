import Foundation
import RedentKit

extension TabController {
    /// ⌘-click: a real tab in the same Space and Container, not a related popup.
    @discardableResult
    func openCommandClickedLink(url: URL, from parent: TabSnapshot) -> any BrowserTab {
        undoHistory.record(session)
        var snapshot = TabSnapshot(url: url)
        snapshot.spaceID = parent.spaceID ?? workspace.selectedSpaceID
        snapshot.containerID = parent.containerID
        snapshot.lifespan = parent.lifespan
        let tab = WebTab(snapshot: snapshot, controller: self)
        webTabs.insert(tab, at: insertIndexAfterCurrent())
        selectedID = tab.id
        tab.wake(loading: url)
        changed()
        return tab
    }
}
