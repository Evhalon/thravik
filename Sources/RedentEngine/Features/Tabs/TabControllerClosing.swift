import Foundation
import RedentKit

extension TabController {
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

    func pushClosed(_ snapshot: TabSnapshot) {
        closedStack.append(snapshot)
        if closedStack.count > Self.closedStackLimit {
            closedStack.removeFirst()
        }
    }
}
