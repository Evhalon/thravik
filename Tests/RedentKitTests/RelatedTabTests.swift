import Foundation
import Testing
@testable import RedentKit

@Suite("Related tabs")
struct RelatedTabTests {
    @Test("A first popup creates a named group around the opener")
    func firstChildCreatesGroup() {
        let parent = TabSnapshot(title: "MiFID Correttiva", spaceID: BrowserSpace.workID)
        let child = TabSnapshot(title: "Child", spaceID: BrowserSpace.workID)
        let outcome = RelatedTabGrouping.outcome(parent: parent, child: child)
        #expect(outcome == .create(name: "MiFID Correttiva", tabIDs: [parent.id, child.id]))
    }

    @Test("A later popup joins the opener's group")
    func laterChildJoins() {
        var parent = TabSnapshot(title: "Parent", spaceID: BrowserSpace.workID)
        parent.groupID = UUID()
        let child = TabSnapshot(title: "Child", spaceID: BrowserSpace.workID)
        #expect(RelatedTabGrouping.outcome(parent: parent, child: child) == .joinExisting)
    }

    @Test("Temporary popups stay out of persisted groups")
    func temporarySkips() {
        let parent = TabSnapshot(title: "Parent", spaceID: BrowserSpace.workID)
        var child = TabSnapshot(title: "Popup", spaceID: BrowserSpace.workID)
        child.lifespan = .temporary(sessionID: UUID(), expiresAt: nil, cleanupOnClose: true)
        #expect(RelatedTabGrouping.outcome(parent: parent, child: child) == .skip)
    }

    @Test("Related children nest under the opener in the sidebar")
    func outlineNestsChildren() throws {
        var parent = TabSnapshot(title: "MiFID Correttiva", spaceID: BrowserSpace.workID)
        var child = TabSnapshot(title: "Correttiva #300192", spaceID: BrowserSpace.workID)
        child.parentTabID = parent.id
        let groupID = UUID()
        parent.groupID = groupID
        child.groupID = groupID
        let group = BrowserGroup(id: groupID, spaceID: BrowserSpace.workID, name: parent.title)
        let outline = SidebarOutline(tabs: [parent, child], groups: [group], spaceID: BrowserSpace.workID)
        #expect(outline.nodes.count == 1)
        guard case let .cluster(cluster) = outline.nodes[0] else {
            Issue.record("expected a cluster")
            return
        }
        #expect(cluster.headerTabID == parent.id)
        #expect(cluster.memberIDs == [child.id])
        #expect(cluster.name == "MiFID Correttiva")
        #expect(outline.tabIDs == [parent.id, child.id])
    }

    @Test("Unrelated tabs stay flat")
    func unrelatedStayFlat() {
        let first = TabSnapshot(title: "One", spaceID: BrowserSpace.workID)
        let second = TabSnapshot(title: "Two", spaceID: BrowserSpace.workID)
        let outline = SidebarOutline(tabs: [first, second], groups: [], spaceID: BrowserSpace.workID)
        #expect(outline.nodes == [.tab(first.id), .tab(second.id)])
        #expect(outline.tabIDs == [first.id, second.id])
    }

    @Test("Swipe paging does not wrap past the ends")
    func pagingStopsAtEnds() {
        let ids = [UUID(), UUID(), UUID()]
        #expect(SpacePaging.neighbor(of: ids[0], in: ids, step: -1) == nil)
        #expect(SpacePaging.neighbor(of: ids[0], in: ids, step: 1) == ids[1])
        #expect(SpacePaging.neighbor(of: ids[2], in: ids, step: 1) == nil)
        #expect(SpacePaging.neighbor(of: ids[1], in: ids, step: -1) == ids[0])
    }

    @Test("Pinning a parent detaches its children")
    func pinDetachesChildren() throws {
        let parent = TabSnapshot(title: "Parent", spaceID: BrowserSpace.workID)
        var child = TabSnapshot(title: "Child", spaceID: BrowserSpace.workID)
        child.parentTabID = parent.id
        var state = WorkspaceState(session: BrowserSession(tabs: [parent, child], selectedTabID: parent.id))
        try state.apply(.setPinned(id: parent.id, isPinned: true))
        #expect(state.session.tabs.first { $0.id == parent.id }?.parentTabID == nil)
        #expect(state.session.tabs.first { $0.id == child.id }?.parentTabID == nil)
    }

    @Test("Empty groups disappear after the last member leaves")
    func emptyGroupsPruned() throws {
        let tab = TabSnapshot(title: "Only", spaceID: BrowserSpace.workID)
        var state = WorkspaceState(session: BrowserSession(tabs: [tab], selectedTabID: tab.id))
        try state.apply(.createGroupWithTabs(spaceID: BrowserSpace.workID, name: "Gone", tabIDs: [tab.id]))
        #expect(state.session.groups.count == 1)
        try state.apply(.moveTabToGroup(tabID: tab.id, groupID: nil))
        #expect(state.session.groups.isEmpty)
        #expect(state.session.tabs.first?.parentTabID == nil)
    }
}
