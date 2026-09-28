import Foundation
import Testing
@testable import RedentKit

@Suite("Pinned tile grid")
struct PinnedTileGeometryTests {
    private let width: CGFloat = 240

    @Test("Up to three pins share one row as wide launchers")
    func wideTiles() {
        let geometry = PinnedTileGeometry(count: 3, width: width)
        #expect(geometry.columns == 3)
        #expect(geometry.tileHeight == PinnedTileGeometry.wideHeight)
        #expect(geometry.tileWidth > geometry.tileHeight)
    }

    @Test("A row holds at most four pins")
    func fourPerRow() {
        let geometry = PinnedTileGeometry(count: 6, width: width)
        #expect(geometry.columns == PinnedTileGeometry.maxColumns)
        #expect(geometry.rows(for: 6) == 2)
        #expect(geometry.origin(of: 4).x == 0)
        #expect(geometry.origin(of: 4).y == geometry.tileHeight + PinnedTileGeometry.spacing)
    }

    @Test("A narrow sidebar wraps before tiles shrink past the smallest square")
    func wrapping() {
        let geometry = PinnedTileGeometry(count: 12, width: 100)
        #expect(geometry.columns == 2)
        #expect(geometry.rows(for: 12) == 6)
        #expect(geometry.tileWidth >= PinnedTileGeometry.smallestSide)
    }

    @Test("No pins take no room")
    func empty() {
        #expect(PinnedTileGeometry(count: 0, width: width).height(for: 0) == 0)
    }
}

@Suite("Pinned page and tab names")
struct TabLabelTests {
    @Test("Pinning remembers the page; unpinning forgets it")
    func pinnedPage() throws {
        let url = URL(string: "https://github.com")
        let tab = TabSnapshot(url: url, title: "GitHub")
        var state = WorkspaceState(session: BrowserSession(tabs: [tab], selectedTabID: tab.id))
        try state.apply(.setPinned(id: tab.id, isPinned: true))
        #expect(state.session.tabs.first?.pinnedURL == url)
        try state.apply(.setPinned(id: tab.id, isPinned: false))
        #expect(state.session.tabs.first?.pinnedURL == nil)
    }

    @Test("Only a pinned tab takes a new pinned page")
    func replacePinnedPage() throws {
        let tab = TabSnapshot(url: URL(string: "https://a.com"))
        var state = WorkspaceState(session: BrowserSession(tabs: [tab], selectedTabID: tab.id))
        let other = URL(string: "https://b.com")
        try state.apply(.setPinnedURL(id: tab.id, url: other))
        #expect(state.session.tabs.first?.pinnedURL == nil)
        try state.apply(.setPinned(id: tab.id, isPinned: true))
        try state.apply(.setPinnedURL(id: tab.id, url: other))
        #expect(state.session.tabs.first?.pinnedURL == other)
    }

    @Test("A blank name restores the page title")
    func rename() throws {
        let tab = TabSnapshot(title: "Page")
        var state = WorkspaceState(session: BrowserSession(tabs: [tab], selectedTabID: tab.id))
        try state.apply(.renameTab(id: tab.id, title: "  Mail  "))
        #expect(state.session.tabs.first?.displayTitle == "Mail")
        try state.apply(.renameTab(id: tab.id, title: " "))
        #expect(state.session.tabs.first?.displayTitle == "Page")
    }

    @Test("Name and pinned page survive a save")
    func codable() throws {
        var tab = TabSnapshot(url: URL(string: "https://a.com"), isPinned: true)
        tab.pinnedURL = URL(string: "https://a.com/home")
        tab.customTitle = "Home"
        let decoded = try JSONDecoder().decode(TabSnapshot.self, from: JSONEncoder().encode(tab))
        #expect(decoded.pinnedURL == tab.pinnedURL)
        #expect(decoded.customTitle == "Home")
    }
}

@Suite("Returning to a pinned page")
struct PinnedPageElsewhereTests {
    @Test("Offered only once the pinned tab has left its page")
    func elsewhere() throws {
        let home = URL(string: "https://mail.example.com")
        var tab = TabSnapshot(url: home, isPinned: true)
        tab.pinnedURL = home
        #expect(tab.pinnedPageElsewhere == nil)
        tab.url = URL(string: "https://mail.example.com/inbox/42")
        #expect(tab.pinnedPageElsewhere == home)
        tab.isPinned = false
        #expect(tab.pinnedPageElsewhere == nil)
    }
}
