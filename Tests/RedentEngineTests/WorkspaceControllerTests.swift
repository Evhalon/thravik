import Foundation
import Testing
import RedentKit
@testable import RedentEngine

@MainActor
struct WorkspaceControllerTests {
    private func controller() -> TabController {
        var first = TabSnapshot(title: "First")
        first.spaceID = BrowserSpace.workID
        var second = TabSnapshot(title: "Second")
        second.spaceID = BrowserSpace.researchID
        return TabController(session: BrowserSession(tabs: [first, second], selectedTabID: first.id),
                             settings: BrowserSettings(), logger: SilentLogger())
    }

    @Test func switchSpacesPreservesTabIdentityAndSelection() throws {
        let browser = controller()
        let original = try #require(browser.selectedID)
        let research = try #require(browser.tabs.last?.id)
        try browser.perform(.selectSpace(id: BrowserSpace.researchID))
        #expect(browser.selectedID == research)
        #expect(browser.visibleTabs.map(\.id) == [research])
        try browser.perform(.selectSpace(id: BrowserSpace.workID))
        #expect(browser.selectedID == original)
        let allSleeping = browser.tabs.allSatisfy { $0.isHibernated }
        #expect(allSleeping)
    }

    @Test func undoMoveRestoresSpaceWithoutRewindingLivePage() throws {
        let browser = controller()
        let tab = try #require(browser.webTabs.first)
        try browser.perform(.moveTab(id: tab.id, toSpaceID: BrowserSpace.researchID, index: nil))
        tab.snapshot.title = "New title"
        browser.undo()
        #expect(tab.snapshot.spaceID == BrowserSpace.workID)
        #expect(tab.snapshot.title == "New title")
        #expect(browser.selectedID == tab.id)
    }

    @Test func closePublishesFinalSessionAndUndoRestoresPosition() throws {
        let browser = controller()
        let original = browser.tabs.map(\.id)
        let id = try #require(original.first)
        var saved: BrowserSession?
        browser.onChange = { saved = browser.session }
        browser.close(id)
        #expect(saved?.tabs.contains { $0.id == id } == false)
        browser.undo()
        #expect(browser.tabs.map(\.id) == original)
        #expect(browser.selectedID == id)
    }

    @Test func pinPublishesAndCanUndo() throws {
        let browser = controller()
        let id = try #require(browser.selectedID)
        browser.togglePin(id)
        #expect(browser.selectedTab?.isPinned == true)
        browser.undo()
        #expect(browser.selectedTab?.isPinned == false)
    }

    @Test func closeOthersDoesNotCloseOtherSpaces() throws {
        let browser = controller()
        let id = try #require(browser.selectedID)
        let other = browser.tabs.last?.id
        browser.closeOthers(than: id)
        #expect(browser.tabs.contains { $0.id == other })
    }

    @Test func closeTabsIsOneUndoableOperation() throws {
        let browser = controller()
        let first = try #require(browser.selectedID)
        let second = browser.newTab(url: nil).id

        browser.closeTabs([first, second])

        #expect(browser.visibleTabs.isEmpty)
        browser.undo()
        #expect(Set(browser.visibleTabs.map(\.id)) == [first, second])
        #expect(browser.selectedID == second)
    }

    @Test func resetWorkspaceRestoresStarterStateAndClearsUndo() throws {
        let browser = controller()
        let oldIDs = Set(browser.tabs.map(\.id))
        browser.close(try #require(browser.selectedID))

        browser.resetWorkspace()

        #expect(browser.session.spaces.map(\.id) == BrowserSpace.starterSpaces.map(\.id))
        #expect(browser.session.spaces.map(\.name) == BrowserSpace.starterSpaces.map(\.name))
        #expect(browser.session.groups.isEmpty)
        #expect(browser.tabs.count == 1)
        #expect(browser.selectedTab?.url == nil)
        #expect(oldIDs.isDisjoint(with: browser.tabs.map(\.id)))
        #expect(!browser.canUndo)
        #expect(!browser.canReopen)
    }
}

private struct SilentLogger: EventLogging {
    func debug(_ message: @autoclosure () -> String) {}
    func notice(_ message: @autoclosure () -> String) {}
    func error(_ message: @autoclosure () -> String) {}
}
