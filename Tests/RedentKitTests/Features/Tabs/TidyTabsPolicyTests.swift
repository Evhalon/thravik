import Foundation
import Testing
@testable import RedentKit

@Suite("Tidy tabs policy")
struct TidyTabsPolicyTests {
    private let now = Date(timeIntervalSince1970: 2_000_000)
    private let threshold: TimeInterval = 24 * 3600
    private let policy = TidyTabsPolicy()

    private func tab(
        id: UUID = UUID(),
        lastActiveAt: Date,
        pinned: Bool = false,
        grouped: Bool = false,
        temporary: Bool = false
    ) -> TabSnapshot {
        var snapshot = TabSnapshot(id: id, title: "Tab", lastActiveAt: lastActiveAt)
        snapshot.isPinned = pinned
        if grouped { snapshot.groupID = UUID() }
        if temporary {
            snapshot.lifespan = .temporary(sessionID: UUID(), expiresAt: nil, cleanupOnClose: true)
        }
        return snapshot
    }

    private func request(
        tabs: [TabSnapshot],
        selected: UUID? = nil,
        split: Set<UUID> = [],
        audio: Set<UUID> = [],
        requiresMinimum: Bool = true
    ) -> TidyTabsPolicy.Request {
        TidyTabsPolicy.Request(
            tabs: tabs,
            selectedTabID: selected,
            splitTabIDs: split,
            playingAudioTabIDs: audio,
            inactivityThreshold: threshold,
            now: now,
            requiresMinimumCount: requiresMinimum
        )
    }

    @Test("Fresh tabs are never candidates")
    func freshTabs() {
        let tab = tab(lastActiveAt: now)
        let ids = policy.candidateIDs(for: request(tabs: [tab], selected: tab.id))
        #expect(ids.isEmpty)
    }

    @Test("Stale loose tabs qualify when enough exist")
    func staleBatch() {
        let stale = (0..<5).map { _ in tab(lastActiveAt: now.addingTimeInterval(-threshold - 60)) }
        let ids = policy.candidateIDs(for: request(tabs: stale))
        #expect(ids.count == 5)
    }

    @Test("Suggestion needs at least five candidates")
    func minimumCount() {
        let stale = (0..<4).map { _ in tab(lastActiveAt: now.addingTimeInterval(-threshold - 60)) }
        #expect(policy.candidateIDs(for: request(tabs: stale)).isEmpty)
        #expect(policy.candidateIDs(for: request(tabs: stale, requiresMinimum: false)).count == 4)
    }

    @Test("Pinned, selected, split, audio, grouped, and temporary tabs are excluded")
    func exclusions() {
        let staleDate = now.addingTimeInterval(-threshold - 60)
        let selected = tab(lastActiveAt: staleDate)
        let pinned = tab(lastActiveAt: staleDate, pinned: true)
        let split = tab(lastActiveAt: staleDate)
        let audio = tab(lastActiveAt: staleDate)
        let grouped = tab(lastActiveAt: staleDate, grouped: true)
        let temporary = tab(lastActiveAt: staleDate, temporary: true)
        let loose = (0..<5).map { _ in tab(lastActiveAt: staleDate) }
        let tabs = loose + [selected, pinned, split, audio, grouped, temporary]
        let ids = policy.candidateIDs(for: request(
            tabs: tabs, selected: selected.id, split: [split.id], audio: [audio.id]
        ))
        #expect(Set(ids) == Set(loose.map(\.id)))
    }
}
