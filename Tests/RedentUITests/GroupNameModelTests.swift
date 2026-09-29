import Foundation
import RedentKit
import Testing
@testable import RedentUI

@Suite("Group names")
@MainActor
struct GroupNameModelTests {
    private let pages = [TabGroupPage(title: "Pull request #12", host: "github.com")]

    @Test("Without a namer the site name stays")
    func noNamerKeepsSite() async {
        let names = GroupNameModel(naming: nil, settleDelay: .zero)
        let cluster = siteCluster(members: [UUID(), UUID()])
        await names.resolve(cluster, isEnabled: true) { pages }
        #expect(names.displayName(for: cluster, isEnabled: true) == "github.com")
    }

    @Test("A generated topic replaces the site name")
    func topicReplacesSite() async {
        let names = GroupNameModel(naming: CountingNamer(answer: "Code review"), settleDelay: .zero)
        let cluster = siteCluster(members: [UUID(), UUID()])
        await names.resolve(cluster, isEnabled: true) { pages }
        #expect(names.displayName(for: cluster, isEnabled: true) == "Code review")
    }

    @Test("Switching naming off falls back to the site name")
    func disabledFallsBack() async {
        let names = GroupNameModel(naming: CountingNamer(answer: "Code review"), settleDelay: .zero)
        let cluster = siteCluster(members: [UUID(), UUID()])
        await names.resolve(cluster, isEnabled: true) { pages }
        #expect(names.displayName(for: cluster, isEnabled: false) == "github.com")
    }

    @Test("A namer with no answer leaves the site name")
    func nilAnswerFallsBack() async {
        let names = GroupNameModel(naming: CountingNamer(answer: nil), settleDelay: .zero)
        let cluster = siteCluster(members: [UUID(), UUID()])
        await names.resolve(cluster, isEnabled: true) { pages }
        #expect(names.displayName(for: cluster, isEnabled: true) == "github.com")
    }

    @Test("A name the user typed is never replaced or sent")
    func userNameKept() async {
        let namer = CountingNamer(answer: "Code review")
        let names = GroupNameModel(naming: namer, settleDelay: .zero)
        let cluster = SidebarNode.Cluster(
            id: UUID(), name: "Taxes", memberIDs: [UUID(), UUID()], isNameAutomatic: false
        )
        await names.resolve(cluster, isEnabled: true) { pages }
        #expect(names.displayName(for: cluster, isEnabled: true) == "Taxes")
        #expect(await namer.calls == 0)
    }

    @Test("The same members are named once; a new member asks again")
    func asksOncePerMembership() async {
        let namer = CountingNamer(answer: "Code review")
        let names = GroupNameModel(naming: namer, settleDelay: .zero)
        let first = UUID()
        let cluster = siteCluster(id: first, members: [first, UUID()])
        await names.resolve(cluster, isEnabled: true) { pages }
        await names.resolve(cluster, isEnabled: true) { pages }
        #expect(await namer.calls == 1)
        let grown = siteCluster(id: first, members: cluster.memberIDs + [UUID()])
        await names.resolve(grown, isEnabled: true) { pages }
        #expect(await namer.calls == 2)
    }

    private func siteCluster(id: UUID = UUID(), members: [UUID]) -> SidebarNode.Cluster {
        SidebarNode.Cluster(id: id, name: "github.com", memberIDs: members, isNameAutomatic: true)
    }
}

private actor CountingNamer: TabGroupNaming {
    private let answer: String?
    private(set) var calls = 0

    init(answer: String?) {
        self.answer = answer
    }

    func name(for pages: [TabGroupPage]) async -> String? {
        calls += 1
        return answer
    }
}
