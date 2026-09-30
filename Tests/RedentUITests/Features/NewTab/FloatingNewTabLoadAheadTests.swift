import Foundation
import RedentKit
import Testing
@testable import RedentUI

/// The floating ⌘T panel loads ahead exactly as the address bar does, so the
/// tab it opens takes a page that is already rendering.
@Suite("Floating new tab loading ahead")
@MainActor
struct FloatingNewTabLoadAheadTests {
    @Test("A page the arrows land on starts loading at once")
    func arrowedPageLoads() throws {
        let page = try #require(URL(string: "https://recent.example/"))
        let browser = FakeBrowser()
        let model = makeTestBrowserModel(tabs: browser)
        let items = FloatingNewTabHome.items(tabs: [], selectedID: nil, bookmarks: [],
                                             recent: [HistoryEntry(url: page)])
        let recent = try #require(items.first { $0.url == page })

        model.loadAhead(recent)

        #expect(browser.prerendered.last == page)
    }

    @Test("A blank tab row loads nothing")
    func blankLoadsNothing() throws {
        let browser = FakeBrowser()
        let model = makeTestBrowserModel(tabs: browser)
        let items = FloatingNewTabHome.items(tabs: [], selectedID: nil, bookmarks: [], recent: [])
        let blank = try #require(items.first { if case .blank = $0.target { true } else { false } })

        model.loadAhead(blank)

        #expect(browser.prerendered.isEmpty)
    }

    @Test("Escape drops what the panel loaded ahead")
    func escapeDiscards() {
        let browser = FakeBrowser()
        let model = makeTestBrowserModel(tabs: browser)
        model.showsFloatingNewTab = true

        model.cancelFloatingNewTab()

        #expect(!model.showsFloatingNewTab)
        #expect(browser.prerendered == [nil])
    }
}
