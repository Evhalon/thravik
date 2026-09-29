import Foundation
import RedentKit
import Testing
@testable import RedentUI

@Suite("Command intents")
struct CommandIntentParserTests {
    private let fixture = CommandFixture()

    @Test("“close youtube tabs” names every YouTube tab, pinned or not, and nothing else")
    func closeSiteTabs() {
        let expected: Set = [fixture.youtube, fixture.pinnedYouTube]
        #expect(fixture.intents("close youtube tabs") == [.closeTabs(expected)])
        #expect(fixture.intents("Close all YouTube tabs!") == [.closeTabs(expected)])
    }

    @Test("“close all tabs” sweeps this Space and leaves pinned tabs alone")
    func closeAll() {
        #expect(fixture.intents("close all tabs") == [.closeTabs([fixture.github, fixture.youtube, fixture.linear])])
    }

    @Test("“close other tabs” keeps the current tab")
    func closeOthers() {
        #expect(fixture.intents("close other tabs") == [.closeTabs([fixture.youtube, fixture.linear])])
    }

    @Test("Half-typed plain commands are not read as a site to close")
    func typingTowardCloseTab() {
        #expect(fixture.intents("close ta").isEmpty)
        #expect(fixture.intents("close window").isEmpty)
        #expect(fixture.intents("close zzz").isEmpty)
    }

    @Test("“reopen last tab” reopens only when something was closed")
    func reopen() {
        #expect(fixture.intents("reopen last tab") == [.reopenLastClosed])
        var empty = fixture
        empty.context.canReopenLastClosed = false
        #expect(empty.intents("reopen last tab").isEmpty)
    }

    @Test("“move this tab to Lisbon” moves the current tab to that Space")
    func moveToSpace() {
        #expect(fixture.intents("move this tab to Lisbon").first == .moveTab(tabID: fixture.github, spaceID: fixture.lisbon.id))
    }

    @Test("“move tab to reading” joins the group; “new window” detaches")
    func moveToGroupAndWindow() {
        #expect(fixture.intents("move tab to reading") == [.moveTabToGroup(tabID: fixture.github, groupID: fixture.reading.id)])
        #expect(fixture.intents("move tab to new window") == [.moveTabToWindow(tabID: fixture.github, windowID: nil)])
    }

    @Test("With no destination, every place is offered — but never across the private boundary")
    func moveListsDestinations() {
        let actions = fixture.intents("move tab to")
        #expect(actions.contains(.moveTab(tabID: fixture.github, spaceID: fixture.lisbon.id)))
        #expect(actions.contains(.moveTabToWindow(tabID: fixture.github, windowID: fixture.otherWindow.id)))
        #expect(actions.contains(.moveTabToWindow(tabID: fixture.github, windowID: nil)))
        #expect(!actions.contains(.moveTabToWindow(tabID: fixture.github, windowID: fixture.privateWindow.id)))
        #expect(!actions.contains(.moveTab(tabID: fixture.github, spaceID: fixture.work.id)))
    }

    @Test("Windows, screens and reloads by name")
    func browserVerbs() {
        #expect(fixture.intents("new window") == [.newWindow])
        #expect(fixture.intents("new private window") == [.newPrivateWindow])
        #expect(fixture.intents("reload all tabs") == [.reloadAllTabs])
        #expect(fixture.intents("open history") == [.showScreen(.history)])
        #expect(fixture.intents("open downloads") == [.showScreen(.downloads)])
        #expect(fixture.intents("open settings") == [.showScreen(.settings)])
    }

    @Test("“resume Lisbon” brings the Space back")
    func resumeSpace() {
        #expect(fixture.intents("resume lisbon").first == .focusSpace(fixture.lisbon.id))
        #expect(fixture.intents("resume reading") == [.focusTab(fixture.lisbonMap)])
    }

    @Test("“new tab …” opens an address as typed, or searches for anything else")
    func newTabWithQuery() throws {
        let address = try #require(URL(string: "https://github.com/Acme"))
        #expect(fixture.intents("new tab github.com/Acme") == [.newTab(address)])
        let search = try #require(SearchEngine.duckduckgo.searchURL(for: "best mechanical keyboards"))
        #expect(fixture.intents("new tab best mechanical keyboards") == [.newTab(search)])
    }
}
