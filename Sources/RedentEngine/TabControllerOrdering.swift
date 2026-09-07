import Foundation
import RedentKit

/// Ordering, pinning, closing, and the reopen stack — split out of
/// `TabController.swift` to keep that file to the core lifecycle.
extension TabController {
    func insertIndexAfterCurrent() -> Int {
        guard let id = selectedID else { return webTabs.count }
        let order = visualTabIDs
        if let visual = order.firstIndex(of: id), visual + 1 < order.count,
           let below = webTabs.firstIndex(where: { $0.id == order[visual + 1] }) {
            return below
        }
        return webTabs.firstIndex(where: { $0.id == id }).map { $0 + 1 } ?? webTabs.count
    }

    func selectionAfterClosing(_ id: UUID) -> UUID? {
        TabCloseSelection.afterClosing(id, in: visualTabIDs)
    }

    private var visualTabIDs: [UUID] {
        SidebarOutline(
            tabs: webTabs.map(\.snapshot),
            groups: workspace.groups,
            spaceID: workspace.selectedSpaceID
        ).tabIDs
    }

    public func closeOthers(than id: UUID) {
        guard visibleTabs.contains(where: { $0.id == id }) else { return }
        undoHistory.record(session)
        let closing = webTabs.filter { $0.id != id && !$0.isPinned && $0.snapshot.spaceID == workspace.selectedSpaceID }
        let closingIDs = Set(closing.map(\.id))
        for tab in closing {
            tab.hibernate()
            if !tab.snapshot.isTemporary { pushClosed(tab.snapshot) }
        }
        webTabs.removeAll { closingIDs.contains($0.id) }
        pruneRelatedAfterRemoval()
        selectedID = id
        changed()
    }

    public func selectNext() {
        guard let index = currentIndex(), !visibleTabs.isEmpty else { return }
        select(visibleTabs[(index + 1) % visibleTabs.count].id)
    }

    public func selectPrevious() {
        guard let index = currentIndex(), !visibleTabs.isEmpty else { return }
        select(visibleTabs[(index - 1 + visibleTabs.count) % visibleTabs.count].id)
    }

    public func move(fromOffsets: IndexSet, toOffset: Int) {
        var ordered = webTabs.filter { $0.snapshot.spaceID == workspace.selectedSpaceID }
        guard fromOffsets.allSatisfy({ ordered.indices.contains($0) }),
              (0...ordered.count).contains(toOffset) else { return }
        undoHistory.record(session)
        ordered.move(fromOffsets: fromOffsets, toOffset: toOffset)
        let replacement = ordered.filter(\.isPinned) + ordered.filter { !$0.isPinned }
        var index = 0
        webTabs = webTabs.map { tab in
            guard tab.snapshot.spaceID == workspace.selectedSpaceID else { return tab }
            defer { index += 1 }
            return replacement[index]
        }
        changed()
    }

    /// Pinned webTabs always sort before unpinned ones.
    public func togglePin(_ id: UUID) {
        guard let tab = webTabs.first(where: { $0.id == id }) else { return }
        try? perform(.setPinned(id: id, isPinned: !tab.isPinned))
    }

    public func reopenLastClosed() {
        while let last = closedStack.last, webTabs.contains(where: { $0.id == last.id }) { closedStack.removeLast() }
        guard var snapshot = closedStack.popLast() else { return }
        if !workspace.spaces.contains(where: { $0.id == snapshot.spaceID }) {
            snapshot.spaceID = workspace.selectedSpaceID
            snapshot.groupID = nil
        }
        undoHistory.record(session)
        let tab = WebTab(snapshot: snapshot, controller: self)
        webTabs.insert(tab, at: insertIndexAfterCurrent())
        selectedID = tab.id
        workspace.selectedSpaceID = snapshot.spaceID
        tab.wake(loading: nil)
        changed()
    }

    /// Forgetting a site has to reach the records that could bring it back.
    /// An undo record carries a whole session, so there is no partial rewind
    /// that keeps the promise — the history goes, and the report says so.
    @discardableResult
    public func forgetClosedTabs(matching domain: String) -> Int {
        let before = closedStack.count
        closedStack.removeAll { $0.origin?.registrableDomain == domain }
        undoHistory.clear()
        return before - closedStack.count
    }

    private func currentIndex() -> Int? {
        guard let id = selectedID else { return nil }
        return visibleTabs.firstIndex { $0.id == id }
    }

}
