import Foundation
import RedentKit

enum FloatingNewTabHome {
    static func items(
        tabs: [TabSnapshot], selectedID: UUID?,
        bookmarks: [Bookmark], recent: [HistoryEntry]
    ) -> [FloatingNewTabItem] {
        let others = tabs.filter { $0.id != selectedID && !$0.isTemporary && $0.url != nil }
            .sorted { $0.lastActiveAt > $1.lastActiveAt }
        var items: [FloatingNewTabItem] = []
        if let last = others.first {
            items.append(tab(last, title: "Switch to last tab", section: .continueBrowsing))
        }
        items += others.dropFirst().prefix(3).map { tab($0, title: $0.displayTitle, section: .tabs) }

        let saved = bookmarks.sorted {
            if $0.isFavorite != $1.isFavorite { return $0.isFavorite }
            return $0.addedAt > $1.addedAt
        }
        items += saved.prefix(3).map { bookmark in
            FloatingNewTabItem(id: "bookmark:\(bookmark.id)", title: bookmark.displayTitle,
                detail: bookmark.origin?.displayHost ?? bookmark.url.absoluteString,
                symbol: "star.fill", faviconData: bookmark.faviconData, url: bookmark.url,
                section: .bookmarks, target: .page(bookmark.url))
        }

        let shownURLs = Set(others.compactMap(\.url)).union(saved.prefix(3).map(\.url))
        items += recent.filter { !shownURLs.contains($0.url) }.prefix(2).map { entry in
            FloatingNewTabItem(id: "history:\(entry.id)", title: entry.displayTitle,
                detail: entry.origin?.displayHost ?? entry.url.absoluteString,
                symbol: "clock", faviconData: nil, url: entry.url,
                section: .recent, target: .page(entry.url))
        }
        items.append(FloatingNewTabItem(id: "blank", title: "Open blank tab", detail: "",
            symbol: "plus", faviconData: nil, url: nil, section: .newTab, target: .blank))
        return items
    }

    private static func tab(_ tab: TabSnapshot, title: String, section: FloatingNewTabItem.Section) -> FloatingNewTabItem {
        FloatingNewTabItem(id: "tab:\(tab.id)", title: title,
            detail: title == "Switch to last tab" ? tab.displayTitle : tab.origin?.displayHost ?? "Tab",
            symbol: "square.on.square", faviconData: tab.faviconData, url: tab.url,
            section: section, target: .tab(tab.id))
    }
}
