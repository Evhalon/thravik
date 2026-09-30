import Foundation
import RedentKit
import Testing
@testable import RedentUI

@Suite("Window presentation")
@MainActor
struct BrowserPresentationTests {
    /// Quitting from the Settings sheet used to leave this binding set, so
    /// SwiftUI re-presented the sheet every time AppKit ended it and the app
    /// never terminated.
    @Test("Nothing stays presented once the window dismisses its modals")
    func clearsEveryPresentation() {
        let model = makeTestBrowserModel()
        model.settings.opensFloatingNewTab = true
        model.sheet = .settings
        model.showCommands()
        model.openNewTab()

        model.dismissPresentations()

        #expect(model.sheet == nil)
        #expect(!model.showsCommandBar)
        #expect(!model.showsFloatingNewTab)
    }

    @Test("Command-T waits for a destination before creating a tab")
    func floatingNewTabCreatesOnlyOnSubmit() {
        let browser = FakeBrowser()
        let model = makeTestBrowserModel(tabs: browser)
        model.settings.opensFloatingNewTab = true
        model.openNewTab()
        model.openNewTab()
        #expect(model.showsFloatingNewTab)
        #expect(browser.openedURLs.isEmpty)

        model.submitFloatingNewTabQuery("example.com")
        #expect(!model.showsFloatingNewTab)
        #expect(browser.openedURLs == [URL(string: "https://example.com")])
    }

    @Test("Choosing a suggestion opens it in a new tab")
    func floatingSuggestionCreatesTab() throws {
        let browser = FakeBrowser()
        let model = makeTestBrowserModel(tabs: browser)
        model.settings.opensFloatingNewTab = true
        let url = try #require(URL(string: "https://example.com/page"))
        let row = AddressSuggestion(kind: .history, title: "Example", subtitle: "example.com", url: url)
        model.openNewTab()

        model.openFloatingNewTabSuggestion(row)

        #expect(browser.openedURLs == [url])
        #expect(!model.showsFloatingNewTab)
    }

    @Test("The suggested last tab switches without opening another tab")
    func floatingLastTabSwitches() throws {
        let browser = FakeBrowser()
        let tab = InertTab()
        let url = try #require(URL(string: "https://example.com"))
        tab.url = url
        tab.snapshot = TabSnapshot(id: tab.id, url: url, title: "Example")
        browser.stubTabs = [tab]
        let model = makeTestBrowserModel(tabs: browser)
        model.settings.opensFloatingNewTab = true
        let item = try #require(FloatingNewTabHome.items(
            tabs: [tab.snapshot], selectedID: nil, bookmarks: [], recent: []
        ).first)
        model.openNewTab()

        model.activateFloatingNewTab(item)

        #expect(browser.selectionCalls == [tab.id])
        #expect(browser.openedURLs.isEmpty)
        #expect(!model.showsFloatingNewTab)
    }

    @Test("Command-T opens a regular new tab by default and floating search remains opt-in")
    func floatingNewTabCanBeDisabled() {
        let browser = FakeBrowser()
        let model = makeTestBrowserModel(tabs: browser)
        model.openNewTab()
        #expect(!model.showsFloatingNewTab)
        #expect(browser.openedURLs.count == 1)
        #expect(browser.openedURLs[0] == nil)

        model.settings.opensFloatingNewTab = true
        model.openNewTab()
        #expect(model.showsFloatingNewTab)
        model.dismissFloatingNewTab()
        #expect(browser.openedURLs.count == 1)

        model.settings.opensFloatingNewTab = false
        model.openNewTab()
        #expect(!model.showsFloatingNewTab)
        #expect(browser.openedURLs.count == 2)
        #expect(browser.openedURLs[1] == nil)
    }
}
