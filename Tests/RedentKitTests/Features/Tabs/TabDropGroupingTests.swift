import Foundation
import Testing
@testable import RedentKit

@Suite("Cluster membership after a drop")
struct TabDropGroupingTests {
    private let group = BrowserGroup(spaceID: BrowserSpace.workID, name: "Cluster")

    private func clustered(_ title: String, under opener: UUID? = nil) -> TabSnapshot {
        var tab = TabSnapshot(title: title, spaceID: BrowserSpace.workID)
        tab.groupID = group.id
        tab.parentTabID = opener
        return tab
    }

    @Test("Landing between two members joins the cluster")
    func joinsBetweenMembers() {
        let header = clustered("Opener")
        let member = clustered("Child", under: header.id)
        let loose = TabSnapshot(title: "Loose", spaceID: BrowserSpace.workID)
        let outcome = TabDropGrouping.outcome(
            moved: loose.id,
            order: [header.id, loose.id, member.id],
            tabs: [header, member, loose],
            groups: [group]
        )
        #expect(outcome == .join(group.id))
    }

    @Test("Landing past the last member stays outside")
    func stopsAtTheClusterEdge() {
        let header = clustered("Opener")
        let member = clustered("Child", under: header.id)
        let loose = TabSnapshot(title: "Loose", spaceID: BrowserSpace.workID)
        let outcome = TabDropGrouping.outcome(
            moved: loose.id,
            order: [header.id, member.id, loose.id],
            tabs: [header, member, loose],
            groups: [group]
        )
        #expect(outcome == .keep)
    }

    @Test("A member dragged out of the cluster leaves it")
    func leavesWhenDraggedOut() {
        let header = clustered("Opener")
        let member = clustered("Child", under: header.id)
        let loose = TabSnapshot(title: "Loose", spaceID: BrowserSpace.workID)
        let outcome = TabDropGrouping.outcome(
            moved: member.id,
            order: [header.id, loose.id, member.id],
            tabs: [header, member, loose],
            groups: [group]
        )
        #expect(outcome == .leave)
    }

    @Test("Reordering inside the cluster changes no membership")
    func reorderInsideKeeps() {
        let header = clustered("Opener")
        let first = clustered("First", under: header.id)
        let second = clustered("Second", under: header.id)
        let outcome = TabDropGrouping.outcome(
            moved: first.id,
            order: [header.id, second.id, first.id],
            tabs: [header, first, second],
            groups: [group]
        )
        #expect(outcome == .keep)
    }

    @Test("A member dragged above the opener leaves the cluster")
    func leavesAboveTheOpener() {
        let header = clustered("Opener")
        let member = clustered("Child", under: header.id)
        let outcome = TabDropGrouping.outcome(
            moved: member.id,
            order: [member.id, header.id],
            tabs: [header, member],
            groups: [group]
        )
        #expect(outcome == .leave)
    }

    @Test("A pinned tab never joins a cluster")
    func pinnedStaysOut() {
        let header = clustered("Opener")
        let member = clustered("Child", under: header.id)
        var pinned = TabSnapshot(title: "Pinned", spaceID: BrowserSpace.workID)
        pinned.isPinned = true
        let outcome = TabDropGrouping.outcome(
            moved: pinned.id,
            order: [header.id, pinned.id, member.id],
            tabs: [header, member, pinned],
            groups: [group]
        )
        #expect(outcome == .keep)
    }

    @Test("An opener-based cluster has no id to join, so the drop only reorders")
    func openerClusterOnlyReorders() {
        let header = TabSnapshot(title: "Opener", spaceID: BrowserSpace.workID)
        var member = TabSnapshot(title: "Child", spaceID: BrowserSpace.workID)
        member.parentTabID = header.id
        let loose = TabSnapshot(title: "Loose", spaceID: BrowserSpace.workID)
        let outcome = TabDropGrouping.outcome(
            moved: loose.id,
            order: [header.id, loose.id, member.id],
            tabs: [header, member, loose],
            groups: []
        )
        #expect(outcome == .keep)
    }
}
