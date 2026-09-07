import Foundation
import Testing
import RedentKit
@testable import RedentEngine

@Suite("Tab hibernation")
@MainActor
struct TabHibernationTests {
    @Test("Switching Space does not tear down a tab that was just on screen")
    func spaceSwitchKeepsWarmTabs() throws {
        let browser = twoSpaceController(hibernation: .aggressive)
        let work = try #require(browser.webTabs.first)
        work.wake(loading: URL(string: "https://example.com"))
        work.snapshot.lastActiveAt = Date(timeIntervalSinceNow: -10_000)

        try browser.perform(.selectSpace(id: BrowserSpace.researchID))
        browser.sweepHibernation(now: .now, keeping: Set([browser.selectedID].compactMap { $0 }))

        #expect(!work.isHibernated)
        #expect(work.webView != nil)
    }

    @Test("A background tab idle past the threshold does hibernate")
    func idleOffScreenTabHibernates() throws {
        let browser = twoSpaceController(hibernation: .aggressive)
        let work = try #require(browser.webTabs.first)
        work.wake(loading: URL(string: "https://example.com"))
        try browser.perform(.selectSpace(id: BrowserSpace.researchID))
        work.snapshot.lastActiveAt = Date(timeIntervalSinceNow: -200)

        browser.sweepHibernation(now: .now, keeping: Set([browser.selectedID].compactMap { $0 }))
        #expect(work.isHibernated)
        #expect(work.webView == nil)
    }

    @Test("A visible tab with a stale timestamp stays awake")
    func onScreenStaleTabStaysAwake() throws {
        let browser = twoSpaceController(hibernation: .aggressive)
        let work = try #require(browser.webTabs.first)
        work.wake(loading: URL(string: "https://example.com"))
        work.snapshot.lastActiveAt = Date(timeIntervalSinceNow: -10_000)

        browser.sweepHibernation(now: .now, keeping: [work.id])
        #expect(!work.isHibernated)
        #expect(work.webView != nil)
    }

    private func twoSpaceController(hibernation: HibernationPolicy) -> TabController {
        var first = TabSnapshot(url: URL(string: "https://work.example"), title: "Work")
        first.spaceID = BrowserSpace.workID
        var second = TabSnapshot(url: URL(string: "https://research.example"), title: "Research")
        second.spaceID = BrowserSpace.researchID
        var settings = BrowserSettings()
        settings.hibernation = hibernation
        return TabController(
            session: BrowserSession(tabs: [first, second], selectedTabID: first.id),
            settings: settings, logger: QuietLogger()
        )
    }
}

private struct QuietLogger: EventLogging {
    func debug(_ message: @autoclosure () -> String) {}
    func notice(_ message: @autoclosure () -> String) {}
    func error(_ message: @autoclosure () -> String) {}
}
