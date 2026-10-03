import Foundation
import Testing
import RedentKit
@testable import RedentEngine

/// Regressions for reopening by entry: stale records, temporary members,
/// deleted Spaces, and insert positions that no longer exist.
@MainActor
struct RecentlyClosedEdgeTests {
    private let groupID = UUID()

    private func tab(_ title: String, space: UUID = BrowserSpace.workID, grouped: Bool = false) -> TabSnapshot {
        var snapshot = TabSnapshot(title: title)
        snapshot.spaceID = space
        if grouped { snapshot.groupID = groupID }
        return snapshot
    }

    private func controller(_ tabs: [TabSnapshot], groupSpace: UUID = BrowserSpace.workID) -> TabController {
        var session = BrowserSession(tabs: tabs, selectedTabID: tabs.first?.id)
        session.groups = [BrowserGroup(id: groupID, spaceID: groupSpace, name: "Batch", colorToken: "orange")]
        return TabController(session: session, settings: BrowserSettings(), logger: QuietLogger())
    }

    @Test("An entry undo already restored is hidden and never duplicates a live tab")
    func undoneEntryIsStale() throws {
        let browser = controller([tab("Keep"), tab("Gone")])
        let gone = try #require(browser.tabs.last?.id)
        browser.close(gone)
        let entry = try #require(browser.recentlyClosed.first?.id)
        browser.undo()
        #expect(browser.recentlyClosed.isEmpty)
        browser.reopenClosed(entry)
        #expect(browser.tabs.filter { $0.id == gone }.count == 1)
    }

    @Test("Closing a group never records its temporary members")
    func groupSkipsTemporary() throws {
        var temporary = tab("Temp", grouped: true)
        temporary.lifespan = .temporary(sessionID: UUID(), expiresAt: nil, cleanupOnClose: true)
        let browser = controller([tab("Other"), tab("Saved", grouped: true), temporary])
        browser.closeGroup(groupID)
        #expect(browser.recentlyClosed.first?.kind == .group(tabCount: 1))
        let entry = try #require(browser.recentlyClosed.first?.id)
        browser.reopenClosed(entry)
        #expect(!browser.tabs.contains { $0.id == temporary.id })
    }

    @Test("Closing a selection closes exactly that selection, never extra group members")
    func bulkCloseKeepsUnselectedMembers() throws {
        var temporary = tab("Temp", grouped: true)
        temporary.lifespan = .temporary(sessionID: UUID(), expiresAt: nil, cleanupOnClose: true)
        let saved = tab("Saved", grouped: true)
        let browser = controller([tab("Other"), saved, temporary])
        browser.closeTabs([saved.id])
        #expect(browser.tabs.contains { $0.id == temporary.id })
        #expect(browser.recentlyClosed.first?.kind == .tab)
    }

    @Test("Selecting every member of a group closes it as one group entry")
    func bulkCloseOfWholeGroup() {
        let one = tab("One", grouped: true)
        let two = tab("Two", grouped: true)
        let browser = controller([tab("Other"), one, two])
        browser.closeTabs([one.id, two.id])
        #expect(browser.recentlyClosed.map(\.kind) == [.group(tabCount: 2)])
    }

    @Test("A group whose Space was deleted reopens, grouped, in a live Space")
    func groupIntoDeletedSpace() throws {
        let one = tab("One", space: BrowserSpace.researchID, grouped: true)
        let browser = controller([tab("Other"), one], groupSpace: BrowserSpace.researchID)
        browser.closeGroup(groupID)
        try browser.perform(.deleteSpace(id: BrowserSpace.researchID))
        let entry = try #require(browser.recentlyClosed.first?.id)
        browser.reopenClosed(entry)
        let reopened = try #require(browser.session.tabs.first { $0.id == one.id })
        let group = try #require(browser.session.groups.first { $0.id == groupID })
        #expect(browser.workspace.spaces.contains { $0.id == group.spaceID })
        #expect(reopened.spaceID == group.spaceID)
        #expect(reopened.groupID == groupID)
    }

    @Test("A tab returns to its old position, clamped when the list shrank")
    func insertIndexRestoredAndClamped() throws {
        let tabs = [tab("A"), tab("B"), tab("C")]
        let browser = controller(tabs)
        browser.close(tabs[1].id)
        let middle = try #require(browser.recentlyClosed.first?.id)
        browser.reopenClosed(middle)
        #expect(browser.tabs.map(\.id) == tabs.map(\.id))
        browser.close(tabs[2].id)
        browser.close(tabs[1].id)
        let last = try #require(browser.recentlyClosed.last?.id)
        browser.reopenClosed(last)
        #expect(browser.tabs.map(\.id) == [tabs[0].id, tabs[2].id])
    }

    @Test("A single tab whose group is gone reopens ungrouped")
    func tabDropsMissingGroup() throws {
        let member = tab("Member", grouped: true)
        let browser = controller([tab("Other"), member])
        browser.close(member.id)
        let entry = try #require(browser.recentlyClosed.first?.id)
        browser.reopenClosed(entry)
        #expect(browser.session.tabs.first { $0.id == member.id }?.groupID == nil)
    }
}

private struct QuietLogger: EventLogging {
    func debug(_ message: @autoclosure () -> String) {}
    func notice(_ message: @autoclosure () -> String) {}
    func error(_ message: @autoclosure () -> String) {}
}
