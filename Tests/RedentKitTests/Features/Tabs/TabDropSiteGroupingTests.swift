import Foundation
import Testing
@testable import RedentKit

@Suite struct TabDropSiteGroupingTests {
    private func tab(_ address: String, apart: Bool = false) throws -> TabSnapshot {
        var snapshot = TabSnapshot(url: try #require(URL(string: address)), spaceID: BrowserSpace.workID)
        snapshot.standsApartFromSite = apart
        return snapshot
    }

    @Test func droppingAwayFromItsSiteSetsATabApart() throws {
        let first = try tab("https://docs.example.com/a")
        let moved = try tab("https://docs.example.com/b")
        let other = try tab("https://news.example.org")
        let lone = try tab("https://mail.example.net")
        let order = [first.id, other.id, moved.id, lone.id]
        let tabs = [first, moved, other, lone]
        #expect(TabDropSiteGrouping.apartness(moved: moved.id, order: order, tabs: tabs) == true)
    }

    @Test func reorderingWithinItsSiteKeepsItIn() throws {
        let first = try tab("https://docs.example.com/a")
        let second = try tab("https://docs.example.com/b")
        let moved = try tab("https://docs.example.com/c")
        let order = [first.id, moved.id, second.id]
        #expect(TabDropSiteGrouping.apartness(moved: moved.id, order: order, tabs: [first, second, moved]) == nil)
    }

    @Test func droppingBesideItsSiteBringsItBack() throws {
        let first = try tab("https://docs.example.com/a")
        let second = try tab("https://docs.example.com/b")
        let moved = try tab("https://docs.example.com/c", apart: true)
        let order = [first.id, second.id, moved.id]
        #expect(TabDropSiteGrouping.apartness(moved: moved.id, order: order, tabs: [first, second, moved]) == false)
    }

    @Test func aTabWithoutSiteKinIsLeftAlone() throws {
        let moved = try tab("https://docs.example.com/a")
        let other = try tab("https://news.example.org")
        #expect(TabDropSiteGrouping.apartness(moved: moved.id, order: [other.id, moved.id], tabs: [moved, other]) == nil)
    }

    @Test func aTabSetApartIsDrawnOnItsOwn() throws {
        let first = try tab("https://docs.example.com/a")
        let second = try tab("https://docs.example.com/b")
        let apart = try tab("https://docs.example.com/c", apart: true)
        let outline = SidebarOutline(tabs: [first, apart, second], groups: [], spaceID: BrowserSpace.workID)
        guard case let .cluster(cluster) = outline.nodes.first else {
            Issue.record("expected the site cluster first")
            return
        }
        #expect(cluster.memberIDs == [first.id, second.id])
        #expect(outline.nodes.dropFirst().first == .tab(apart.id))
    }

    @Test func beingApartSurvivesARestart() throws {
        let apart = try tab("https://docs.example.com/c", apart: true)
        let decoded = try JSONDecoder().decode(TabSnapshot.self, from: JSONEncoder().encode(apart))
        #expect(decoded.standsApartFromSite)
    }
}
