import Foundation
import RedentKit

extension TabController {
    public func perform(_ action: WorkspaceAction) throws {
        let before = session
        var state = WorkspaceState(session: before)
        try state.apply(action)
        let next = state.session
        switch action {
        case .selectSpace, .selectTab:
            // Clicking a tab changes two fields. Comparing whole sessions — and
            // then rebuilding every tab — to discover that is the expensive way
            // to learn nothing, and clicking tabs is what people do most.
            guard next.selectedTabID != before.selectedTabID
                || next.selectedSpaceID != before.selectedSpaceID else { return }
            applySelection(next)
        default:
            guard next != before else { return }
            undoHistory.record(before)
            reconcile(next)
        }
    }

    /// The tab list is untouched by a selection change, so only the selection
    /// itself moves.
    private func applySelection(_ state: BrowserSession) {
        touchActivity(of: selectedID)
        workspace.spaces = state.spaces
        workspace.selectedSpaceID = state.selectedSpaceID
        workspace.selectedTabID = state.selectedTabID
        selectedID = state.selectedTabID
        touchActivity(of: selectedID)
        onChange?()
    }

    public func undo() {
        guard var previous = undoHistory.pop() else { return }
        let current = Dictionary(uniqueKeysWithValues: webTabs.map { ($0.id, $0.snapshot) })
        previous.tabs = previous.tabs.map { snapshot in
            guard let live = current[snapshot.id] else { return snapshot }
            var restored = snapshot
            restored.url = live.url
            restored.title = live.title
            restored.faviconData = live.faviconData
            restored.lastActiveAt = live.lastActiveAt
            restored.timeline = live.timeline
            return restored
        }
        previous.tabs.append(contentsOf: webTabs.filter { $0.snapshot.isTemporary }.map(\.snapshot))
        reconcile(previous)
    }

    func reconcile(_ state: BrowserSession) {
        let existing = Dictionary(uniqueKeysWithValues: webTabs.map { ($0.id, $0) })
        let retained = Set(state.tabs.map(\.id))
        for tab in webTabs where !retained.contains(tab.id) { tab.hibernate() }
        webTabs = state.tabs.map { snapshot in
            guard let tab = existing[snapshot.id] else { return WebTab(snapshot: snapshot, controller: self) }
            // A live view is bound to the data store it was built with, so a tab
            // that changed Container has to be rebuilt against the new one.
            if tab.snapshot.browsingContext != snapshot.browsingContext { tab.hibernate() }
            tab.snapshot = snapshot
            tab.isPinned = snapshot.isPinned
            return tab
        }
        workspace = state
        selectedID = state.selectedTabID
        changed()
    }
}
