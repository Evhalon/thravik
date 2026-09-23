import Foundation
import RedentKit

/// Actions on tabs, Spaces and groups — the window's own workspace.
extension BrowserModel {
    /// - Returns: false when `action` is not a workspace action.
    func routeWorkspace(_ action: BrowserAction) throws -> Bool {
        switch action {
        case .newTab(let url):
            if url == nil { openNewTab() } else { tabs.newTab(url: url) }
        case .navigate(let url): navigate(to: url)
        case .focusTab(let id): try tabs.perform(.selectTab(id: id))
        case .closeTab(let id): tabs.close(id)
        case .closeTabs(let ids): tabs.closeTabs(ids)
        case .reopenLastClosed: tabs.reopenLastClosed()
        case .duplicateTab(let id): try duplicateTab(id)
        case .reloadAllTabs: reloadAllTabs()
        case .pinTab(let id, let pinned): try tabs.perform(.setPinned(id: id, isPinned: pinned))
        case .focusSpace(let id): try tabs.perform(.selectSpace(id: id))
        case .createSpace(let name): try tabs.perform(.createSpace(name: name))
        case .renameSpace(let id, let name): try tabs.perform(.renameSpace(id: id, name: name))
        case .deleteSpace(let id): try tabs.perform(.deleteSpace(id: id))
        case .moveTab(let id, let space): try tabs.perform(.moveTab(id: id, toSpaceID: space, index: nil))
        case .moveTabToGroup(let id, let group): try moveTab(id, toGroup: group)
        default: return false
        }
        return true
    }

    private func duplicateTab(_ id: UUID) throws {
        guard let url = tabs.tabs.first(where: { $0.id == id })?.url else { throw CommandActionError.unavailable }
        tabs.newTab(url: url)
    }

    /// Only tabs with a live page reload. A hibernated one loads fresh when
    /// it is next shown, and waking every tab at once is the memory spike
    /// hibernation exists to prevent.
    private func reloadAllTabs() {
        for tab in tabs.visibleTabs where !tab.isHibernated { tab.reload() }
    }

    /// A group belongs to one Space, so a tab joining it from elsewhere moves
    /// there first.
    private func moveTab(_ id: UUID, toGroup groupID: UUID) throws {
        guard let group = tabs.session.groups.first(where: { $0.id == groupID }) else {
            throw CommandActionError.unavailable
        }
        if tabs.session.tabs.first(where: { $0.id == id })?.spaceID != group.spaceID {
            try tabs.perform(.moveTab(id: id, toSpaceID: group.spaceID, index: nil))
        }
        try tabs.perform(.moveTabToGroup(tabID: id, groupID: groupID))
    }
}

/// An action whose target vanished between the row being drawn and pressed.
enum CommandActionError: Error {
    case unavailable
}
