import Foundation
import RedentKit

enum TabCommandDescriptors {
    static let all: [CommandDescriptor] = [
        CommandDescriptor(id: "new-tab", title: "New Tab", keywords: ["open", "create"], symbol: "plus") { _, _ in .newTab(nil) },
        CommandDescriptor(id: "close-tab", title: "Close Tab", keywords: ["remove"], symbol: "xmark") { context, _ in
            context.selectedTabID.map(BrowserAction.closeTab)
        },
        CommandDescriptor(id: "reopen-tab", title: "Reopen Closed Tab", keywords: ["restore", "undo"], symbol: "arrow.uturn.backward") { context, _ in
            context.canReopenLastClosed ? .reopenLastClosed : nil
        },
        CommandDescriptor(id: "duplicate-tab", title: "Duplicate Tab", keywords: ["copy", "clone"], symbol: "plus.square.on.square") { context, _ in
            guard let tab = context.selectedTab, tab.url != nil else { return nil }
            return .duplicateTab(tab.id)
        },
        CommandDescriptor(id: "pin-tab", title: "Pin Current Tab", keywords: ["unpin", "favorite"], symbol: "pin") { context, _ in
            context.selectedTab.map { .pinTab($0.id, isPinned: !$0.isPinned) }
        },
        CommandDescriptor(id: "close-other-tabs", title: "Close Other Tabs", keywords: ["others", "clean"], symbol: "xmark.square") { context, _ in
            let others = context.tabs.filter {
                $0.id != context.selectedTabID && !$0.isPinned && $0.spaceID == context.selectedSpaceID
            }
            return others.isEmpty ? nil : .closeTabs(Set(others.map(\.id)))
        },
        CommandDescriptor(id: "reload-all", title: "Reload All Tabs", keywords: ["refresh", "every"], symbol: "arrow.clockwise.circle") { context, _ in
            context.tabs.isEmpty ? nil : .reloadAllTabs
        },
        CommandDescriptor(id: "move-tab-prompt", title: "Move Tab to…", keywords: ["space", "group", "window", "send"],
                          symbol: "arrow.right.square", completion: "move tab to "),
        CommandDescriptor(id: "move-tab", title: "Move Tab", keywords: ["space", "to"], symbol: "arrow.right") { context, query in
            guard let tabID = context.selectedTabID,
                  let name = CommandArguments.after("move tab to", in: query),
                  let spaceID = context.spaces.first(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame })?.id
            else { return nil }
            return .moveTab(tabID: tabID, spaceID: spaceID)
        }
    ]
}
