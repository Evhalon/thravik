import Foundation
import Testing
import RedentKit
@testable import RedentEngine

/// Close and open must move selection to the row above/below, never the first tab.
@Suite("Tab selection after open and close")
@MainActor
struct TabSelectionTests {
    private func controller(titles: [String]) -> TabController {
        let tabs = titles.map { title -> TabSnapshot in
            var tab = TabSnapshot(title: title)
            tab.spaceID = BrowserSpace.workID
            return tab
        }
        return TabController(
            session: BrowserSession(tabs: tabs, selectedTabID: tabs.last?.id),
            settings: BrowserSettings(),
            logger: MuteLogger()
        )
    }

    @Test("Closing the last tab selects the one above")
    func closeLastSelectsAbove() throws {
        let browser = controller(titles: ["One", "Two", "Three"])
        let ids = browser.visibleTabs.map(\.id)
        browser.close(ids[2])
        #expect(browser.selectedID == ids[1])
        browser.close(ids[1])
        #expect(browser.selectedID == ids[0])
    }

    @Test("Closing the top tab selects the one that was beneath")
    func closeTopSelectsBelow() throws {
        let browser = controller(titles: ["One", "Two", "Three"])
        let ids = browser.visibleTabs.map(\.id)
        browser.select(ids[0])
        browser.close(ids[0])
        #expect(browser.selectedID == ids[1])
    }

    @Test("Closing an unselected tab leaves selection alone")
    func closeOtherKeepsSelection() throws {
        let browser = controller(titles: ["One", "Two", "Three"])
        let ids = browser.visibleTabs.map(\.id)
        browser.select(ids[2])
        browser.close(ids[0])
        #expect(browser.selectedID == ids[2])
    }

    @Test("A new tab lands under the current one and takes selection")
    func newTabInsertsBelow() throws {
        let browser = controller(titles: ["One", "Two", "Three"])
        let ids = browser.visibleTabs.map(\.id)
        browser.select(ids[1])
        let created = browser.newTab(url: nil)
        #expect(browser.selectedID == created.id)
        #expect(browser.visibleTabs.map(\.id) == [ids[0], ids[1], created.id, ids[2]])
    }

    @Test("Closing a new tab returns to the one above it")
    func closeNewTabReturnsAbove() throws {
        let browser = controller(titles: ["One", "Two"])
        let original = try #require(browser.selectedID)
        let created = browser.newTab(url: nil)
        browser.close(created.id)
        #expect(browser.selectedID == original)
    }

    @Test("applyOrder permutes named tabs")
    func applyOrderPermutes() {
        let browser = controller(titles: ["A", "B", "C", "D"])
        let ids = browser.visibleTabs.map(\.id)
        browser.applyOrder([ids[2], ids[0], ids[1], ids[3]])
        #expect(browser.visibleTabs.map(\.id) == [ids[2], ids[0], ids[1], ids[3]])
    }

    @Test("applyOrder leaves unnamed tabs in their seats")
    func applyOrderKeepsUnnamed() {
        let browser = controller(titles: ["A", "B", "C"])
        let ids = browser.visibleTabs.map(\.id)
        browser.applyOrder([ids[2], ids[0]])
        #expect(browser.visibleTabs.map(\.id) == [ids[2], ids[1], ids[0]])
    }
}

private struct MuteLogger: EventLogging {
    func debug(_ message: @autoclosure () -> String) {}
    func notice(_ message: @autoclosure () -> String) {}
    func error(_ message: @autoclosure () -> String) {}
}
