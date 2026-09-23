import Foundation
import RedentKit
import Testing
@testable import RedentUI

@MainActor
@Suite("Command Center actions")
struct CommandRoutingTests {
    private func window(pages: [String]) -> (BrowserModel, FakeBrowser, RecordingWindowDirectory) {
        let browser = FakeBrowser()
        browser.stubTabs = pages.map { address in
            let tab = InertTab()
            tab.url = URL(string: address)
            return tab
        }
        browser.selectedID = browser.stubTabs.first?.id
        let model = makeTestBrowserModel(tabs: browser)
        let directory = RecordingWindowDirectory()
        model.windowDirectory = directory
        return (model, browser, directory)
    }

    @Test("Closing a sweep of tabs is one operation, so one ⌥⌘Z brings them back")
    func closeTabsIsOneOperation() {
        let (model, browser, _) = window(pages: ["https://a.example", "https://b.example"])
        let ids = Set(browser.stubTabs.map(\.id))
        model.execute(.closeTabs(ids))
        #expect(browser.closedSets == [ids])
        #expect(browser.closed.isEmpty)
    }

    @Test("Duplicating opens the same address in a new tab")
    func duplicate() throws {
        let (model, browser, _) = window(pages: ["https://a.example/page"])
        model.execute(.duplicateTab(try #require(browser.stubTabs.first).id))
        #expect(browser.openedURLs == [URL(string: "https://a.example/page")])
    }

    @Test("A tab leaves only once the other window has taken it")
    func moveToWindow() throws {
        let (model, browser, directory) = window(pages: ["https://a.example"])
        let id = try #require(browser.stubTabs.first).id
        model.execute(.moveTabToWindow(tabID: id, windowID: nil))
        #expect(directory.adopted.map(\.url) == [URL(string: "https://a.example")])
        #expect(browser.closed == [id])
    }

    @Test("A refused move keeps the tab and says so")
    func refusedMove() throws {
        let (model, browser, directory) = window(pages: ["https://a.example"])
        directory.acceptsTabs = false
        model.execute(.moveTabToWindow(tabID: try #require(browser.stubTabs.first).id, windowID: UUID()))
        #expect(browser.closed.isEmpty)
        #expect(model.actionError != nil)
    }

    @Test("⌘K opens the bar and ⌘K again closes it")
    func toggle() {
        let (model, _, _) = window(pages: [])
        model.toggleCommands()
        #expect(model.showsCommandBar)
        model.toggleCommands()
        #expect(!model.showsCommandBar)
    }

    @Test("⌘2 with the bar open runs its second row instead of switching tabs")
    func numberKeysRunRows() async throws {
        let (model, browser, _) = window(pages: ["https://a.example", "https://b.example"])
        let current = try #require(browser.selectedID)
        model.showCommands()
        #expect(model.commandBar.rows[1].action == .closeTab(current))

        model.selectTab(at: 2)
        for _ in 0..<20 where browser.closed.isEmpty { await Task.yield() }

        #expect(browser.closed == [current])
        #expect(browser.selectionCalls.isEmpty)
        #expect(!model.showsCommandBar)
    }
}
