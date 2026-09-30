import Foundation
import Testing
import RedentKit
@testable import RedentEngine

@MainActor
struct SpaceUndoTests {
    private func controller() -> TabController {
        var first = TabSnapshot(title: "First")
        first.spaceID = BrowserSpace.workID
        var second = TabSnapshot(title: "Second")
        second.spaceID = BrowserSpace.researchID
        return TabController(session: BrowserSession(tabs: [first, second], selectedTabID: first.id),
                             settings: BrowserSettings(), logger: SpaceUndoLogger())
    }

    @Test func undoingSpaceRenameKeepsTabsClosedAfterIt() throws {
        let browser = controller()
        try browser.perform(.renameSpace(id: BrowserSpace.workID, name: "Office"))
        let closed = try #require(browser.selectedID)
        browser.close(closed)

        browser.undoSpaces()

        #expect(browser.session.spaces.first { $0.id == BrowserSpace.workID }?.name != "Office")
        #expect(!browser.tabs.contains { $0.id == closed })
        #expect(browser.canUndo)
        #expect(!browser.canUndoSpaces)
    }

    @Test func undoingSpaceRenameKeepsTabsOpenedAfterIt() throws {
        let browser = controller()
        try browser.perform(.renameSpace(id: BrowserSpace.workID, name: "Office"))
        let opened = browser.newTab(url: nil).id

        browser.undoSpaces()

        #expect(browser.tabs.contains { $0.id == opened })
    }

    @Test func undoingSpaceDeletionRevivesItsTabs() throws {
        let browser = controller()
        let research = try #require(browser.tabs.first { $0.snapshot.spaceID == BrowserSpace.researchID }?.id)
        try browser.perform(.deleteSpace(id: BrowserSpace.researchID))
        #expect(!browser.tabs.contains { $0.id == research })

        browser.undoSpaces()

        #expect(browser.session.spaces.contains { $0.id == BrowserSpace.researchID })
        #expect(browser.tabs.first { $0.id == research }?.snapshot.spaceID == BrowserSpace.researchID)
    }

    @Test func undoingCreatedSpaceKeepsTabsOpenedInIt() throws {
        let browser = controller()
        try browser.perform(.createSpace(name: "Garden", look: nil))
        let garden = try #require(browser.session.spaces.first { $0.name == "Garden" }?.id)
        try browser.perform(.selectSpace(id: garden))
        let opened = browser.newTab(url: nil).id

        browser.undoSpaces()

        #expect(!browser.session.spaces.contains { $0.id == garden })
        let moved = try #require(browser.tabs.first { $0.id == opened })
        #expect(moved.snapshot.spaceID.map { id in browser.session.spaces.contains { $0.id == id } } == true)
    }

    @Test func undoingTabCloseDoesNotReapplyAnUndoneSpaceEdit() throws {
        let browser = controller()
        try browser.perform(.renameSpace(id: BrowserSpace.researchID, name: "Reading"))
        let closed = try #require(browser.selectedID)
        browser.close(closed)
        browser.undoSpaces()

        browser.undo()

        #expect(browser.tabs.contains { $0.id == closed })
        #expect(browser.session.spaces.first { $0.id == BrowserSpace.researchID }?.name != "Reading")
    }
}

private struct SpaceUndoLogger: EventLogging {
    func debug(_ message: @autoclosure () -> String) {}
    func notice(_ message: @autoclosure () -> String) {}
    func error(_ message: @autoclosure () -> String) {}
}
