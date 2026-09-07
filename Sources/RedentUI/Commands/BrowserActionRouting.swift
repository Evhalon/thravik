import Foundation
import RedentKit

extension BrowserModel {
    public func showCommands() {
        showsCommandBar = true
        refreshCommandContext()
        commandBar.query = ""
    }

    public func dismissCommands() {
        showsCommandBar = false
        commandBar.close()
    }

    public func execute(_ action: BrowserAction) {
        dismissCommands()
        do {
            try route(action)
            address.finishEditing()
            address.sync(with: selectedTab)
        } catch {
            actionError = "This action is no longer available. The workspace was not changed."
        }
    }

    private func route(_ action: BrowserAction) throws {
        switch action {
        case .newTab(let url):
            if url == nil { openNewTab() } else { tabs.newTab(url: url) }
        case .navigate(let url): navigate(to: url)
        case .focusTab(let id): try tabs.perform(.selectTab(id: id))
        case .closeTab(let id): tabs.close(id)
        case .reopenLastClosed: tabs.reopenLastClosed()
        case .pinTab(let id, let pinned): try tabs.perform(.setPinned(id: id, isPinned: pinned))
        case .focusSpace(let id): try tabs.perform(.selectSpace(id: id))
        case .createSpace(let name): try tabs.perform(.createSpace(name: name))
        case .renameSpace(let id, let name): try tabs.perform(.renameSpace(id: id, name: name))
        case .deleteSpace(let id): try tabs.perform(.deleteSpace(id: id))
        case .moveTab(let id, let space): try tabs.perform(.moveTab(id: id, toSpaceID: space, index: nil))
        case .goBack: selectedTab?.goBack()
        case .goForward: selectedTab?.goForward()
        case .toggleFocusMode: toggleFocusMode()
        case .toggleSidebar: toggleSidebar()
        }
    }

    func refreshCommandContext() {
        guard showsCommandBar else { return }
        let session = tabs.session
        let names = Dictionary(uniqueKeysWithValues: session.spaces.map { ($0.id, $0.name) })
        let tabContexts = tabs.tabs.filter { !$0.snapshot.isTemporary }.map { tab in
            CommandTabContext(id: tab.id, title: tab.snapshot.displayTitle,
                values: .init(url: tab.url, isPinned: tab.isPinned, spaceID: tab.snapshot.spaceID,
                              spaceName: tab.snapshot.spaceID.flatMap { names[$0] }))
        }
        let spaces = session.spaces.map {
            CommandSpaceContext(id: $0.id, name: $0.name, tabIDs: $0.tabIDs,
                                isCurrent: $0.id == session.selectedSpaceID)
        }
        commandBar.updateContext(CommandBarContext(tabs: tabContexts, spaces: spaces,
            selectedTabID: tabs.selectedID, selectedSpaceID: session.selectedSpaceID,
            canReopenLastClosed: tabs.canReopen))
    }
}
