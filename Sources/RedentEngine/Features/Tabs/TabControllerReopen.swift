import Foundation
import RedentKit

extension TabController {
    public var recentlyClosed: [RecentlyClosedEntry] {
        guard !isPrivate else { return [] }
        return closedStack.listings(liveTabIDs: liveTabIDs)
    }

    public func reopenClosed(_ entryID: UUID) {
        guard !isPrivate, let record = closedStack.remove(id: entryID, liveTabIDs: liveTabIDs) else { return }
        applyReopen(record, afterCurrent: false)
    }

    public func reopenLastClosed() {
        guard !isPrivate, let record = closedStack.popLast(liveTabIDs: liveTabIDs) else { return }
        applyReopen(record, afterCurrent: true)
    }

    private var liveTabIDs: Set<UUID> { Set(webTabs.map(\.id)) }

    private func applyReopen(_ record: ClosedStackRecord, afterCurrent: Bool) {
        undoHistory.record(session)
        switch record.payload {
        case .tab(var snapshot):
            reopenTab(&snapshot, record: record, afterCurrent: afterCurrent)
        case .group(var group, var tabs):
            reopenGroup(&group, tabs: &tabs, record: record, afterCurrent: afterCurrent)
        }
        changed()
    }

    private func reopenTab(_ snapshot: inout TabSnapshot, record: ClosedStackRecord, afterCurrent: Bool) {
        normalizeSpace(&snapshot)
        if let groupID = snapshot.groupID, !workspace.groups.contains(where: { $0.id == groupID }) {
            snapshot.groupID = nil
        }
        let index = afterCurrent ? insertIndexAfterCurrent() : min(record.insertIndex, webTabs.count)
        let tab = WebTab(snapshot: snapshot, controller: self)
        webTabs.insert(tab, at: index)
        updateSelectedID(tab.id)
        workspace.selectedSpaceID = snapshot.spaceID
        tab.wake(loading: nil)
    }

    private func reopenGroup(
        _ group: inout BrowserGroup,
        tabs: inout [TabSnapshot],
        record: ClosedStackRecord,
        afterCurrent: Bool
    ) {
        let live = liveTabIDs
        tabs.removeAll { live.contains($0.id) }
        guard !tabs.isEmpty else { return }
        normalizeGroupSpace(&group, tabs: &tabs)
        if !workspace.groups.contains(where: { $0.id == group.id }) {
            workspace.groups.append(group)
        }
        var insertAt = afterCurrent ? insertIndexAfterCurrent() : min(record.insertIndex, webTabs.count)
        var selected: UUID?
        for index in tabs.indices {
            tabs[index].groupID = group.id
            tabs[index].spaceID = group.spaceID
            let tab = WebTab(snapshot: tabs[index], controller: self)
            webTabs.insert(tab, at: min(insertAt, webTabs.count))
            insertAt += 1
            selected = tab.id
            tab.wake(loading: nil)
        }
        if let selected { updateSelectedID(selected) }
        workspace.selectedSpaceID = group.spaceID
    }

    private func normalizeSpace(_ snapshot: inout TabSnapshot) {
        guard let spaceID = snapshot.spaceID,
              workspace.spaces.contains(where: { $0.id == spaceID }) else {
            snapshot.spaceID = workspace.selectedSpaceID
            snapshot.groupID = nil
            return
        }
    }

    private func normalizeGroupSpace(_ group: inout BrowserGroup, tabs: inout [TabSnapshot]) {
        guard !workspace.spaces.contains(where: { $0.id == group.spaceID }) else { return }
        let fallback = workspace.selectedSpaceID ?? workspace.spaces.first?.id ?? BrowserSpace.workID
        group = BrowserGroup(
            id: group.id,
            spaceID: fallback,
            name: group.name,
            colorToken: group.colorToken,
            tabIDs: tabs.map(\.id),
            isNameAutomatic: group.isNameAutomatic
        )
    }
}
