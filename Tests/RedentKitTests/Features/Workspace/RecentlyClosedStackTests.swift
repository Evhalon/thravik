import Foundation
import Testing
@testable import RedentKit

struct RecentlyClosedStackTests {
    private func tab(_ title: String, host: String? = nil) -> TabSnapshot {
        var snapshot = TabSnapshot(title: title, spaceID: BrowserSpace.workID)
        if let host, let url = URL(string: "https://\(host)") {
            snapshot.url = url
        }
        return snapshot
    }

    @Test("Stack keeps newest first in listings and enforces the bound")
    func orderingAndBound() {
        var stack = RecentlyClosedStack()
        for index in 0..<12 {
            stack.pushTab(tab("Tab \(index)"), insertIndex: index, limit: 10)
        }
        #expect(stack.records.count == 10)
        let titles = stack.listings().map(\.title)
        #expect(titles.first == "Tab 11")
        #expect(titles.last == "Tab 2")
    }

    @Test("Stack logic treats a live duplicate tab entry as stale")
    func staleTabEntry() {
        let live = tab("Live")
        var stack = RecentlyClosedStack()
        stack.pushTab(live, insertIndex: 0, limit: 10)
        let popped = stack.popLast(liveTabIDs: [live.id])
        #expect(popped == nil)
        #expect(stack.records.isEmpty)
    }

    @Test("Removing one entry leaves the rest intact")
    func removeSingleEntry() {
        var stack = RecentlyClosedStack()
        let first = ClosedStackRecord(insertIndex: 0, payload: .tab(tab("First")))
        let second = ClosedStackRecord(insertIndex: 1, payload: .tab(tab("Second")))
        stack.push(first, limit: 10)
        stack.push(second, limit: 10)
        let removed = stack.remove(id: first.id)
        #expect(removed?.id == first.id)
        #expect(stack.records.map(\.id) == [second.id])
        #expect(stack.listings().map(\.title) == ["Second"])
    }

    @Test("Group listings carry tab counts and restore payloads stay grouped")
    func groupEntry() {
        let group = BrowserGroup(spaceID: BrowserSpace.workID, name: "Research", colorToken: "green")
        let members = [tab("One"), tab("Two")]
        var stack = RecentlyClosedStack()
        stack.pushGroup(group: group, tabs: members, insertIndex: 3, limit: 10)
        let entry = stack.listings().first
        #expect(entry?.title == "Research")
        #expect(entry?.kind == .group(tabCount: 2))
        if case .group(let stored, let tabs) = stack.records.first?.payload {
            #expect(stored.name == "Research")
            #expect(tabs.count == 2)
        } else {
            Issue.record("Expected a group payload")
        }
    }

    @Test("Forget drops tabs and groups that mention the domain")
    func forgetDomain() {
        var stack = RecentlyClosedStack()
        stack.pushTab(tab("Keep"), insertIndex: 0, limit: 10)
        stack.pushTab(tab("Drop", host: "forget.example"), insertIndex: 1, limit: 10)
        let group = BrowserGroup(spaceID: BrowserSpace.workID, name: "Mixed")
        stack.pushGroup(group: group, tabs: [tab("Also", host: "forget.example")], insertIndex: 2, limit: 10)
        let removed = stack.forget(domain: "forget.example")
        #expect(removed == 2)
        #expect(stack.records.count == 1)
        #expect(stack.records.first?.listing().title == "Keep")
    }
}
