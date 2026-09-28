import Foundation
import RedentKit

/// What a pinned tile's menu does beyond an ordinary tab's.
extension BrowserModel {
    /// Selects the tab too: asking to go back to a page means wanting to see it.
    public func returnToPinnedPage(_ tabID: UUID) {
        guard let tab = tabs.tabs.first(where: { $0.id == tabID }),
              let home = tab.snapshot.pinnedPageElsewhere else { return }
        tabs.select(tabID)
        tab.load(home)
    }

    /// The page the tab shows now becomes the one it returns to.
    public func pinCurrentPage(_ tabID: UUID) {
        guard let url = tabs.tabs.first(where: { $0.id == tabID })?.url else { return }
        try? tabs.perform(.setPinnedURL(id: tabID, url: url))
    }

    public func renameTab(_ tabID: UUID, to title: String?) {
        try? tabs.perform(.renameTab(id: tabID, title: title))
    }

    /// The Spaces a tab could move to: every one but its own.
    public func spaces(besides tabID: UUID) -> [BrowserSpace] {
        let current = tabs.tabs.first { $0.id == tabID }?.snapshot.spaceID
        return tabs.session.spaces.filter { $0.id != current }
    }
}
