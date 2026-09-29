import Foundation
import Testing
@testable import RedentKit

@Suite("Workspace domain")
struct WorkspaceTests {
    @Test("Legacy sessions migrate into starter spaces and the Work Container")
    func legacyMigration() throws {
        let id = UUID()
        let data = Data("{\"tabs\":[{\"id\":\"\(id.uuidString)\",\"title\":\"Old\",\"isPinned\":true,\"lastActiveAt\":0}],\"selectedTabID\":\"\(id.uuidString)\"}".utf8)
        let session = try JSONDecoder().decode(BrowserSession.self, from: data)
        #expect(session.spaces.count == 4)
        #expect(session.tabs.first?.spaceID == BrowserSpace.workID)
        #expect(session.tabs.first?.containerID == BrowserContainer.defaultID)
    }

    @Test("Reducer moves tabs and preserves per-space selection")
    func reducer() throws {
        let tab = TabSnapshot(title: "A")
        var state = WorkspaceState(session: BrowserSession(tabs: [tab], selectedTabID: tab.id))
        try state.apply(.moveTab(id: tab.id, toSpaceID: BrowserSpace.researchID, index: nil))
        #expect(state.session.tabs.first?.spaceID == BrowserSpace.researchID)
        #expect(state.session.selectedSpaceID == BrowserSpace.researchID)
        #expect(state.session.spaces.first { $0.id == BrowserSpace.researchID }?.selectedTabID == tab.id)
    }

    @Test("Persistent snapshots exclude temporary tabs")
    func temporaryFiltering() {
        var temporary = TabSnapshot(title: "Private")
        temporary.lifespan = .temporary(sessionID: UUID(), expiresAt: nil, cleanupOnClose: true)
        let snapshot = WorkspaceSnapshot(session: BrowserSession(tabs: [temporary]))
        #expect(snapshot.tabs.isEmpty)
    }

    @Test("A selection outside the active Space is pulled back into it")
    func selectionNormalization() {
        var work = TabSnapshot(title: "Work")
        work.spaceID = BrowserSpace.workID
        var research = TabSnapshot(title: "Research")
        research.spaceID = BrowserSpace.researchID
        var session = BrowserSession(tabs: [work, research], selectedTabID: work.id)
        session.selectedTabID = research.id

        let state = WorkspaceState(session: session)
        #expect(state.session.selectedSpaceID == BrowserSpace.workID)
        #expect(state.session.selectedTabID == work.id)
    }

    @Test("A selection naming a Space that no longer exists falls back to a real one")
    func unknownSpaceFallback() {
        var tab = TabSnapshot(title: "Work")
        tab.spaceID = BrowserSpace.workID
        var session = BrowserSession(tabs: [tab], selectedTabID: tab.id)
        session.selectedSpaceID = UUID()

        let state = WorkspaceState(session: session)
        #expect(state.session.spaces.contains { $0.id == state.session.selectedSpaceID })
    }

    @Test("Grouping suggestions are deterministic and ignore pinned or grouped tabs")
    func groupingSuggestions() {
        let first = TabSnapshot(url: URL(string: "https://one.example.com/a"))
        let second = TabSnapshot(url: URL(string: "https://one.example.com/b"))
        var pinned = TabSnapshot(url: URL(string: "https://one.example.com/c"), isPinned: true)
        pinned.spaceID = first.spaceID
        let suggestions = GroupingSuggestionService().suggestions(for: [first, second, pinned])
        #expect(suggestions.count == 1)
        #expect(suggestions[0].tabIDs == [first.id, second.id])
        #expect(suggestions[0].reason.contains("2 tabs"))
    }
}
