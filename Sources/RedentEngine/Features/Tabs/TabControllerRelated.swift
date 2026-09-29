import Foundation
import RedentKit

extension TabController {
    /// Groups a popup with its opener the first time they become related.
    /// Returns true when `reconcile` already published the change.
    func adoptRelatedTab(parent: TabSnapshot, child: WebTab) -> Bool {
        guard case let .create(name, tabIDs) = RelatedTabGrouping.outcome(
            parent: parent, child: child.snapshot
        ) else { return false }
        guard let spaceID = child.snapshot.spaceID else { return false }
        var state = WorkspaceState(session: session)
        try? state.apply(.createGroupWithTabs(spaceID: spaceID, name: name, tabIDs: tabIDs))
        reconcile(state.session)
        return true
    }

    func pruneRelatedAfterRemoval() {
        let remaining = Set(webTabs.map(\.id))
        for tab in webTabs {
            if let parent = tab.snapshot.parentTabID, !remaining.contains(parent) {
                tab.snapshot.parentTabID = nil
            }
        }
        workspace.groups.removeAll { group in
            !webTabs.contains { $0.snapshot.groupID == group.id }
        }
    }
}
