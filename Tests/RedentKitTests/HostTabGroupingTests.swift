import Foundation
import Testing
@testable import RedentKit

@Suite("Host tab grouping")
struct HostTabGroupingTests {
    @Test("Two tabs sharing a host form a visual cluster")
    func sharedHostClusters() throws {
        let first = try tab("https://tickets.example.com/one")
        let second = try tab("https://tickets.example.com/two")

        let outline = SidebarOutline(
            tabs: [first, second], groups: [], spaceID: BrowserSpace.workID
        )

        guard case let .cluster(cluster) = outline.nodes.first else {
            Issue.record("expected a host cluster")
            return
        }
        #expect(cluster.name == "tickets.example.com")
        #expect(cluster.headerTabID == nil)
        #expect(cluster.memberIDs == [first.id, second.id])
    }

    @Test("A host represented by one tab stays flat")
    func loneHostStaysFlat() throws {
        let first = try tab("https://one.example.com/page")
        let second = try tab("https://two.example.com/page")

        let outline = SidebarOutline(
            tabs: [first, second], groups: [], spaceID: BrowserSpace.workID
        )

        #expect(outline.nodes == [.tab(first.id), .tab(second.id)])
    }

    private func tab(_ address: String) throws -> TabSnapshot {
        let url = try #require(URL(string: address))
        return TabSnapshot(url: url, spaceID: BrowserSpace.workID)
    }
}
