import Foundation
import RedentKit
import Testing
@testable import RedentUI

/// Beyond searches, the address bar starts loading a page before return only
/// when it is a site the user already knows — never a half-typed address.
@Suite("Loading ahead of return")
@MainActor
struct LoadAheadTests {
    @Test("A site completed from saved pages starts loading before return")
    func completionLoadsAhead() async throws {
        let site = try #require(URL(string: "https://github.com/"))
        let browser = FakeBrowser()
        let model = makeTestBrowserModel(tabs: browser, bookmarks: SavedPages([Bookmark(url: site, title: "GitHub")]))

        model.queryChanged("git", from: .addressBar)
        await model.suggestions.queryInFlight?.value
        let completed = try #require(model.suggestions.completion)
        for _ in 0..<100 where browser.prerendered.last != completed.url {
            try await Task.sleep(for: .milliseconds(20))
        }

        #expect(completed.url.host() == "github.com")
        #expect(browser.prerendered.last == completed.url)
    }

    @Test("Arrowing onto a saved page loads it at once")
    func highlightedRowLoadsAtOnce() async throws {
        let page = try #require(URL(string: "https://forums.swift.org/latest"))
        let browser = FakeBrowser()
        let model = makeTestBrowserModel(tabs: browser, bookmarks: SavedPages([Bookmark(url: page, title: "Swift forums")]))
        model.queryChanged("swift", from: .addressBar)
        await model.suggestions.queryInFlight?.value

        #expect(model.moveSuggestionHighlight(by: 1, from: .addressBar))
        #expect(model.moveSuggestionHighlight(by: 1, from: .addressBar))

        #expect(model.suggestions.highlightedRow?.url == page)
        #expect(browser.prerendered.last == page)
    }
}

private struct SavedPages: BookmarkStoring {
    let items: [Bookmark]
    init(_ items: [Bookmark]) { self.items = items }

    func all(in spaceID: UUID?) async -> [Bookmark] { items }
    func favorites(in spaceID: UUID?) async -> [Bookmark] { [] }
    func search(_ query: String, in spaceID: UUID?, limit: Int) async -> [Bookmark] {
        items.filter { $0.displayTitle.lowercased().contains(query.lowercased()) }
    }
    func bookmark(for url: URL, in spaceID: UUID?) async -> Bookmark? { items.first { $0.url == url } }
    func save(_ bookmark: Bookmark) async {}
    func merge(_ bookmarks: [Bookmark]) async -> Int { 0 }
    func delete(_ id: UUID) async {}
}
