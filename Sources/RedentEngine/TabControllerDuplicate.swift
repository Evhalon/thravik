import Foundation
import RedentKit

extension TabController {
    /// Opens a second copy of a tab directly beneath it. The copy stays in the
    /// source's Space, Container, group and lifespan: duplicating a signed-in
    /// page into a different storage boundary would quietly sign the user out.
    @discardableResult
    public func duplicateTab(_ id: UUID) -> (any BrowserTab)? {
        guard let index = webTabs.firstIndex(where: { $0.id == id }) else { return nil }
        let source = webTabs[index].snapshot
        undoHistory.record(session)
        var snapshot = TabSnapshot(url: source.url, title: source.title, faviconData: source.faviconData)
        snapshot.spaceID = source.spaceID
        snapshot.containerID = source.containerID
        snapshot.groupID = source.groupID
        snapshot.lifespan = source.lifespan
        snapshot.zoom = source.zoom
        let tab = WebTab(snapshot: snapshot, controller: self)
        webTabs.insert(tab, at: index + 1)
        updateSelectedID(tab.id)
        if let url = source.url { tab.wake(loading: url) }
        changed()
        return tab
    }
}
