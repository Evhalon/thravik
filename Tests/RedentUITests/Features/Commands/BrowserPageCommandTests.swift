import Foundation
import RedentKit
import Testing
@testable import RedentUI

/// Answers lookups from what it has actually been given, so a toggle can be
/// observed both ways round.
actor ToggleBookmarkStore: BookmarkStoring {
    private var items: [Bookmark] = []
    private(set) var deletions: [UUID] = []

    func all(in spaceID: UUID?) async -> [Bookmark] { items }
    func favorites(in spaceID: UUID?) async -> [Bookmark] { items }
    func search(_ query: String, in spaceID: UUID?, limit: Int) async -> [Bookmark] { items }
    func bookmark(for url: URL, in spaceID: UUID?) async -> Bookmark? {
        items.first { $0.url == url }
    }
    func save(_ bookmark: Bookmark) async { items.append(bookmark) }
    func merge(_ bookmarks: [Bookmark]) async -> Int { 0 }
    func delete(_ id: UUID) async {
        deletions.append(id)
        items.removeAll { $0.id == id }
    }
}

@MainActor
@Suite("Page commands")
struct BrowserPageCommandTests {
    private func windowWithTabs(_ count: Int) -> (BrowserModel, FakeBrowser) {
        let browser = FakeBrowser()
        browser.stubTabs = (0..<count).map { index in
            let tab = InertTab()
            tab.url = URL(string: "https://site\(index).example")
            return tab
        }
        browser.selectedID = browser.stubTabs.first?.id
        return (makeTestBrowserModel(tabs: browser), browser)
    }

    @Test("⌘1 through ⌘8 pick that seat in the current Space")
    func numberedSelection() {
        let (model, browser) = windowWithTabs(4)
        model.selectTab(at: 3)
        #expect(browser.selectionCalls == [browser.stubTabs[2].id])
    }

    @Test("⌘9 is the last tab, however many there are")
    func lastTabShortcut() {
        let (model, browser) = windowWithTabs(4)
        model.selectTab(at: 9)
        #expect(browser.selectionCalls == [browser.stubTabs[3].id])
    }

    @Test("A number past the end selects nothing at all")
    func ignoresMissingSeats() {
        let (model, browser) = windowWithTabs(2)
        model.selectTab(at: 5)
        #expect(browser.selectionCalls.isEmpty)
    }

    @Test("The find bar only opens over a page, and closes clean")
    func findBarLifecycle() {
        let (model, _) = windowWithTabs(1)
        model.showFindBar()
        #expect(model.chrome.isFindBarVisible)

        model.chrome.findMatches = .empty
        #expect(model.chrome.findFailed)

        model.closeFindBar()
        #expect(!model.chrome.isFindBarVisible)
        #expect(model.chrome.findMatches == nil)
        #expect(!model.chrome.findFailed)
    }

    @Test("A new tab has no address bar, so ⌘L goes to the page's own field")
    func addressFocusFallsBackToTheNewTabField() {
        let (model, _) = windowWithTabs(0)
        let epoch = model.centerSearchFocusEpoch
        model.focusAddressBar()
        #expect(model.centerSearchFocusEpoch == epoch + 1)
        #expect(model.chrome.addressFocusEpoch == 0)
    }

    @Test("⌘D saves the page, then removes what it saved")
    func bookmarkToggle() async throws {
        let browser = FakeBrowser()
        let tab = InertTab()
        tab.url = URL(string: "https://example.com/article")
        let icon = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
        tab.snapshot.faviconData = icon
        browser.stubTabs = [tab]
        browser.selectedID = tab.id
        let store = ToggleBookmarkStore()
        let model = makeTestBrowserModel(tabs: browser, bookmarks: store)

        await model.toggleBookmark()
        #expect(model.chrome.isBookmarked)
        let saved = try #require(await store.all(in: nil).first)
        #expect(saved.faviconData == icon)

        await model.toggleBookmark()
        #expect(!model.chrome.isBookmarked)
        #expect(await store.deletions.count == 1)
    }
}
