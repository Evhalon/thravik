import Foundation
import RedentKit
import Testing
@testable import RedentUI

@Suite("Bookmarks bar actions")
@MainActor
struct BookmarksBarActionTests {
    @Test("⌘-click opens behind the page; ⌘⇧-click opens and selects")
    func openTargets() throws {
        let browser = FakeBrowser()
        let model = makeTestBrowserModel(tabs: browser)
        let url = try #require(URL(string: "https://example.com"))

        model.openBookmark(url, target: .backgroundTab)
        #expect(browser.backgroundURLs == [url])
        #expect(browser.openedURLs.isEmpty)

        model.openBookmark(url, target: .foregroundTab)
        #expect(browser.openedURLs == [url])
        #expect(browser.backgroundURLs == [url])
    }

    @Test("Deleting a folder removes nested pages and nested folder records")
    func deleteFolderIsDeep() async throws {
        let space = BrowserSpace.workID
        let nested = Bookmark(
            url: try #require(URL(string: "https://deep.example")), folderPath: ["Work", "Specs"], spaceID: space
        )
        let keep = Bookmark(url: try #require(URL(string: "https://keep.example")), spaceID: space)
        let store = BarStoreFake(
            bookmarks: [nested, keep],
            folders: [BookmarkFolder(path: ["Work", "Specs"], spaceID: space)]
        )
        let bar = BookmarksBarModel(store: store)
        await bar.load(in: space)
        guard case .folder(let work, _) = bar.items.last else {
            Issue.record("expected the Work chip")
            return
        }

        await bar.deleteFolder(work)

        #expect(await store.bookmarks.map(\.id) == [keep.id])
        #expect(await store.savedFolders.isEmpty)
        #expect(bar.items.map(\.title) == [keep.displayTitle])
    }

    @Test("Measured widths are capped and folders reserve room for their glyphs")
    func measuredWidths() async throws {
        let space = BrowserSpace.workID
        let long = Bookmark(
            url: try #require(URL(string: "https://a.example")), title: String(repeating: "W", count: 80),
            spaceID: space, addedAt: Date(timeIntervalSince1970: 2)
        )
        let short = Bookmark(
            url: try #require(URL(string: "https://b.example")), title: "Go",
            spaceID: space, addedAt: Date(timeIntervalSince1970: 1)
        )
        let filed = Bookmark(
            url: try #require(URL(string: "https://c.example")), title: "x", folderPath: ["Go"], spaceID: space
        )
        let bar = BookmarksBarModel(store: BarStoreFake(bookmarks: [long, short, filed]))
        await bar.load(in: space)

        let widths = try #require(bar.itemWidths.count == 3 ? bar.itemWidths : nil)
        #expect(widths[0] <= Double(BookmarksBarChipMetrics.maxWidth) + 8)
        #expect(widths[1] < widths[0])
        #expect(widths[2] > widths[1])
    }

    @Test("Writes through the broadcasting store announce a change", .timeLimit(.minutes(1)))
    func broadcastsWrites() async throws {
        let base = BarStoreFake(bookmarks: [])
        let store = BroadcastingBookmarkStore(base)
        var changes = NotificationCenter.default.notifications(named: .bookmarksDidChange).makeAsyncIterator()
        await store.save(Bookmark(url: try #require(URL(string: "https://example.com"))))
        #expect(await changes.next() != nil)
        #expect(await base.bookmarks.count == 1)
    }
}
