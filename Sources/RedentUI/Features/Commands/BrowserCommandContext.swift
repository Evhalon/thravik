import Foundation
import RedentKit

/// The snapshot of the window the Command Bar searches and validates against.
extension BrowserModel {
    func refreshCommandContext() {
        guard showsCommandBar else { return }
        let session = tabs.session
        let names = spaceNames
        let tabContexts = tabs.tabs.filter { !$0.snapshot.isTemporary }.map { tab in
            var values = CommandTabContext.Values(url: tab.url, isPinned: tab.isPinned, spaceID: tab.snapshot.spaceID,
                                                  spaceName: tab.snapshot.spaceID.flatMap { names[$0] })
            values.faviconData = tab.snapshot.faviconData
            values.groupID = tab.snapshot.groupID
            return CommandTabContext(id: tab.id, title: tab.snapshot.displayTitle, values: values)
        }
        let spaces = session.spaces.map {
            CommandSpaceContext(id: $0.id, name: $0.name, tabIDs: $0.tabIDs,
                                isCurrent: $0.id == session.selectedSpaceID)
        }
        var context = CommandBarContext(tabs: tabContexts, spaces: spaces,
            selectedTabID: tabs.selectedID, selectedSpaceID: session.selectedSpaceID,
            canReopenLastClosed: tabs.canReopen)
        context.groups = session.groups.map { group in
            CommandGroupContext(id: group.id, name: group.name, spaceID: group.spaceID,
                                spaceName: names[group.spaceID], tabIDs: group.tabIDs)
        }
        context.windows = windowDirectory?.windows ?? []
        context.webApps = isPrivate ? [] : webApps
        context.isPrivate = isPrivate
        commandBar.updateContext(context)
    }
}
