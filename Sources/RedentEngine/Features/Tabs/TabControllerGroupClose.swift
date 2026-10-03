import Foundation
import RedentKit

extension TabController {
    public func closeGroup(_ groupID: UUID) {
        guard let group = workspace.groups.first(where: { $0.id == groupID }) else { return }
        closeTabsAsGroup(closableMembers(of: groupID), group: group)
    }

    func matchingBrowserGroup(forClosing ids: Set<UUID>) -> BrowserGroup? {
        workspace.groups.first { group in
            let members = closableMembers(of: group.id)
            return !members.isEmpty && members == ids
        }
    }

    func closeTabsAsGroup(_ ids: Set<UUID>, group: BrowserGroup) {
        let closing = webTabs.filter { ids.contains($0.id) }
        guard !closing.isEmpty else { return }
        let outline = SidebarOutline(tabs: webTabs.map(\.snapshot), groups: workspace.groups, spaceID: group.spaceID)
        let orderedIDs = outline.tabIDs.filter { ids.contains($0) }
        let recordable = orderedIDs.compactMap { id in
            closing.first { $0.id == id && !$0.snapshot.isTemporary }?.snapshot
        }
        let insertIndex = webTabs.firstIndex(where: { $0.id == orderedIDs.first }) ?? webTabs.count
        if !recordable.isEmpty { undoHistory.record(session) }
        pushClosedGroup(group: group, tabs: recordable, insertIndex: insertIndex)
        let selectedWasClosed = selectedID.map(ids.contains) ?? false
        for tab in closing { tab.hibernate() }
        webTabs.removeAll { ids.contains($0.id) }
        pruneRelatedAfterRemoval()
        if selectedWasClosed { updateSelectedID(visibleTabs.first?.id) }
        changed()
    }

    /// Pinning drops a tab out of its group, so every member is closable.
    private func closableMembers(of groupID: UUID) -> Set<UUID> {
        Set(webTabs.filter { $0.snapshot.groupID == groupID && !$0.isPinned }.map(\.id))
    }
}
