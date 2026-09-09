import Foundation
import RedentKit

extension TabController {
    /// ⌘-click: a real tab in the same Space and Container, not a related popup.
    ///
    /// It opens behind the current page unless the caller asks otherwise: the
    /// point of ⌘-clicking a link is to keep reading where you are and come
    /// back to it later.
    @discardableResult
    func openCommandClickedLink(
        url: URL, from parent: TabSnapshot, selecting: Bool = false
    ) -> any BrowserTab {
        undoHistory.record(session)
        var snapshot = TabSnapshot(url: url)
        snapshot.spaceID = parent.spaceID ?? workspace.selectedSpaceID
        snapshot.containerID = parent.containerID
        snapshot.lifespan = parent.lifespan
        let tab = WebTab(snapshot: snapshot, controller: self)
        webTabs.insert(tab, at: insertIndexAfterCurrent())
        if selecting { updateSelectedID(tab.id) }
        tab.wake(loading: url)
        changed()
        return tab
    }
}
