import Foundation
import RedentKit
import Testing
@testable import RedentUI

@Suite("Floating new tab suggestions")
struct FloatingNewTabHomeTests {
    @Test("The last active tab leads, followed by tabs, bookmarks, and recent pages")
    func homeOrder() throws {
        let firstURL = try #require(URL(string: "https://first.example"))
        let lastURL = try #require(URL(string: "https://last.example"))
        let savedURL = try #require(URL(string: "https://saved.example"))
        let recentURL = try #require(URL(string: "https://recent.example"))
        let first = TabSnapshot(url: firstURL, title: "First", lastActiveAt: .distantPast)
        let last = TabSnapshot(url: lastURL, title: "Last", lastActiveAt: .now)
        let bookmark = Bookmark(url: savedURL, title: "Saved", isFavorite: true)
        let recent = [HistoryEntry(url: savedURL), HistoryEntry(url: recentURL)]

        let items = FloatingNewTabHome.items(tabs: [first, last], selectedID: nil,
                                             bookmarks: [bookmark], recent: recent)

        #expect(items.map(\.title) == ["Switch to last tab", "First", "Saved", "recent.example", "Open blank tab"])
        guard case .tab(let id) = items[0].target else {
            Issue.record("First row must switch tabs")
            return
        }
        #expect(id == last.id)
    }
}
