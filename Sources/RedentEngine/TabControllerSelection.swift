import Foundation
import RedentKit

/// Selection, the published session snapshot, and the change notification the
/// window listens to. Split from `TabController.swift` so that file keeps to
/// the tab lifecycle itself.
extension TabController {
    public var selectedTab: (any BrowserTab)? {
        webTabs.first { $0.id == selectedID }
    }

    /// Clicking a tab is the most common thing anyone does here, so it does not
    /// go through the reducer: rebuilding the whole session, re-deriving every
    /// Space's membership and comparing it back is a lot of work to move one id.
    public func select(_ id: UUID) {
        guard selectedID != id, let tab = webTabs.first(where: { $0.id == id }) else { return }
        touchActivity(of: selectedID)
        selectedID = id
        if let spaceID = tab.snapshot.spaceID, workspace.selectedSpaceID != spaceID {
            workspace.selectedSpaceID = spaceID
        }
        touchActivity(of: id)
        selectionChanged()
    }

    public var session: BrowserSession {
        var result = workspace
        result.tabs = webTabs.map(\.snapshot)
        result.selectedTabID = selectedID
        if let index = result.spaces.firstIndex(where: { $0.id == result.selectedSpaceID }) {
            result.spaces[index].selectedTabID = selectedID
        }
        for index in result.groups.indices {
            let id = result.groups[index].id
            result.groups[index].tabIDs = result.tabs.filter { $0.groupID == id }.map(\.id)
        }
        result.groups.removeAll { group in !result.tabs.contains { $0.groupID == group.id } }
        return result
    }

    /// `workspace` holds the structural session — Spaces, Containers, groups,
    /// selection. The tabs are rebuilt from the live views on demand in
    /// `session`, so copying them in here on every change was work nobody read.
    func changed() {
        syncSelection()
        contexts.sync(webTabs.map(\.snapshot.browsingContext))
        onChange?()
    }

    /// The selection moved but the tab set did not, so there is nothing for the
    /// context registry to re-count.
    func selectionChanged() {
        syncSelection()
        onChange?()
    }

    private func syncSelection() {
        guard workspace.selectedTabID != selectedID else { return }
        workspace.selectedTabID = selectedID
        if let index = workspace.spaces.firstIndex(where: { $0.id == workspace.selectedSpaceID }) {
            workspace.spaces[index].selectedTabID = selectedID
        }
    }
}
