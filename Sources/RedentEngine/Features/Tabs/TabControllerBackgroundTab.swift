import Foundation
import RedentKit

extension TabController {
    /// A tab in the current Space that loads behind the page being read, as a
    /// ⌘-clicked bookmark does. Selection, and so auto-float, stays put.
    @discardableResult
    public func newBackgroundTab(url: URL) -> any BrowserTab {
        undoHistory.record(session)
        var snapshot = TabSnapshot(url: url)
        snapshot.spaceID = workspace.selectedSpaceID
        snapshot.containerID = workspace.spaces.first { $0.id == workspace.selectedSpaceID }?.containerID
        if let privateSessionID {
            snapshot.lifespan = .temporary(sessionID: privateSessionID, expiresAt: nil, cleanupOnClose: true)
        }
        let tab = WebTab(snapshot: snapshot, controller: self)
        applySensitiveSitePolicy(to: [tab])
        webTabs.insert(tab, at: insertIndex(opening: url, in: snapshot.spaceID))
        tab.wake(loading: url)
        changed()
        return tab
    }
}
