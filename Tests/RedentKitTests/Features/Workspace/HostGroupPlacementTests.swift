import Foundation
import Testing
@testable import RedentKit

@Suite("Host group placement")
struct HostGroupPlacementTests {
    private let space = UUID()

    private func tab(_ address: String) -> TabSnapshot {
        var snapshot = TabSnapshot(url: URL(string: address))
        snapshot.spaceID = space
        return snapshot
    }

    @Test("A same-site tab goes after the group's last tab")
    func insertsAfterGroup() {
        let tabs = [tab("https://a.com"), tab("https://b.com/1"), tab("https://www.b.com/2"), tab("https://c.com")]
        #expect(HostGroupPlacement.insertionIndex(forHost: "b.com", spaceID: space, in: tabs) == 3)
    }

    @Test("A site with no tab in the Space has no preferred place")
    func noSiblingNoPlacement() {
        let tabs = [tab("https://a.com"), tab("https://b.com")]
        #expect(HostGroupPlacement.insertionIndex(forHost: "c.com", spaceID: space, in: tabs) == nil)
        #expect(HostGroupPlacement.insertionIndex(forHost: "b.com", spaceID: UUID(), in: tabs) == nil)
    }

    @Test("Pinned and grouped tabs are not part of a site group")
    func ignoresPinnedAndGrouped() {
        var pinned = tab("https://b.com/1")
        pinned.isPinned = true
        var grouped = tab("https://b.com/2")
        grouped.groupID = UUID()
        let tabs = [tab("https://a.com"), pinned, grouped]
        #expect(HostGroupPlacement.insertionIndex(forHost: "b.com", spaceID: space, in: tabs) == nil)
    }

    @Test("A tab redirected ahead of its site's group moves after it")
    func settlesTabAheadOfGroup() {
        let moved = tab("https://b.com/new")
        let tabs = [tab("https://a.com"), moved, tab("https://c.com"), tab("https://b.com/1"), tab("https://b.com/2")]
        #expect(HostGroupPlacement.settledIndex(of: moved.id, in: tabs) == 4)
    }

    @Test("A tab already inside its site's group stays put")
    func leavesGroupMemberAlone() {
        let member = tab("https://b.com/2")
        let tabs = [tab("https://b.com/1"), tab("https://a.com"), member]
        #expect(HostGroupPlacement.settledIndex(of: member.id, in: tabs) == nil)
    }
}
