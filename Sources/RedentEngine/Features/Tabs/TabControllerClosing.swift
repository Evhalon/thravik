import Foundation
import RedentKit

extension TabController {
    func selectionAfterClosing(_ id: UUID) -> UUID? {
        // Saved pins remain available without reopening a page during close.
        let pinnedIDs = Set(webTabs.filter(\.isPinned).map(\.id))
        let order = visualTabIDs.filter { $0 == id || !pinnedIDs.contains($0) }
        return TabCloseSelection.afterClosing(id, in: order)
    }

    /// Closing a pin closes its page, never the pin: the tile stays, asleep,
    /// and wakes on its pinned page next time it is chosen.
    func releasePinned(_ tab: WebTab) {
        if selectedID == tab.id { updateSelectedID(selectionAfterClosing(tab.id)) }
        tab.hibernate()
        if let home = tab.snapshot.pinnedURL, tab.snapshot.url != home {
            // The title and icon belong to the page it wandered to.
            tab.beginNavigation(to: home)
            tab.title = ""
            tab.snapshot.title = ""
            tab.snapshot.faviconData = nil
        }
        changed()
    }

    func pushClosed(_ snapshot: TabSnapshot, insertIndex: Int) {
        guard !isPrivate else { return }
        closedStack.pushTab(snapshot, insertIndex: insertIndex, limit: Self.closedStackLimit)
    }

    func pushClosedGroup(group: BrowserGroup, tabs: [TabSnapshot], insertIndex: Int) {
        guard !isPrivate else { return }
        closedStack.pushGroup(
            group: group,
            tabs: tabs,
            insertIndex: insertIndex,
            limit: Self.closedStackLimit
        )
    }
}
