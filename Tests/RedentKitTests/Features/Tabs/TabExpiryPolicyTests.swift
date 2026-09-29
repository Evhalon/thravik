import Foundation
import Testing
@testable import RedentKit

@Suite("Temporary tab expiry")
struct TabExpiryPolicyTests {
    private let now = Date(timeIntervalSince1970: 1_000_000)

    private func temporary(expiresAt: Date?) -> TabSnapshot {
        var tab = TabSnapshot(title: "Temp")
        tab.lifespan = .temporary(sessionID: UUID(), expiresAt: expiresAt, cleanupOnClose: true)
        return tab
    }

    @Test("A tab with no deadline is never touched")
    func noDeadline() {
        let tab = temporary(expiresAt: nil)
        let decision = TabExpiryPolicy().decide(tabs: [tab], selectedID: nil, now: now)
        #expect(decision.isEmpty)
    }

    @Test("A normal tab is never expired")
    func normalTabs() {
        let tab = TabSnapshot(title: "Normal")
        let decision = TabExpiryPolicy().decide(tabs: [tab], selectedID: tab.id, now: now)
        #expect(decision.isEmpty)
    }

    @Test("A background tab past its deadline closes itself")
    func backgroundCloses() {
        let tab = temporary(expiresAt: now.addingTimeInterval(-1))
        let decision = TabExpiryPolicy().decide(tabs: [tab], selectedID: UUID(), now: now)
        #expect(decision.closing == [tab.id])
        #expect(decision.prompting == nil)
    }

    @Test("The tab being read is offered, never closed underneath the user")
    func selectedIsPrompted() {
        let tab = temporary(expiresAt: now.addingTimeInterval(-1))
        let decision = TabExpiryPolicy().decide(tabs: [tab], selectedID: tab.id, now: now)
        #expect(decision.closing.isEmpty)
        #expect(decision.prompting == tab.id)
    }

    @Test("A deadline still ahead does nothing")
    func futureDeadline() {
        let tab = temporary(expiresAt: now.addingTimeInterval(60))
        let decision = TabExpiryPolicy().decide(tabs: [tab], selectedID: nil, now: now)
        #expect(decision.isEmpty)
    }

    @Test("Sleeping past several deadlines expires them all at once")
    func wakeAfterSleep() {
        let first = temporary(expiresAt: now.addingTimeInterval(-3600))
        let second = temporary(expiresAt: now.addingTimeInterval(-60))
        let alive = temporary(expiresAt: now.addingTimeInterval(60))
        let decision = TabExpiryPolicy().decide(
            tabs: [first, second, alive], selectedID: nil, now: now
        )
        #expect(decision.closing == [first.id, second.id])
    }
}
