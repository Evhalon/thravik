import Foundation
import RedentKit

extension TabController {
    /// Testing helper: backdates background tabs so Tidy Tabs can be exercised
    /// without waiting for real idle time.
    public func backdateInactiveTabsForTidyDemo(spaceID: UUID?, lastActiveAt: Date) {
        guard let spaceID else { return }
        for tab in webTabs where tab.snapshot.spaceID == spaceID
            && tab.id != selectedID && !tab.isPinned && !tab.snapshot.isTemporary {
            tab.snapshot.lastActiveAt = lastActiveAt
        }
        changed()
    }
}
