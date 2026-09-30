import Foundation
import Testing
import RedentKit
@testable import RedentEngine

/// Closing a pinned tab closes its page and keeps the pin.
@MainActor
struct PinnedCloseTests {
    private let home = URL(string: "https://mail.example.com/inbox")
    private let elsewhere = URL(string: "https://news.example.org/story")

    private func controller() -> (TabController, pinned: UUID, other: UUID) {
        var pinned = TabSnapshot(url: elsewhere, title: "Story", isPinned: true)
        pinned.pinnedURL = home
        pinned.faviconData = Data([1])
        let other = TabSnapshot(url: home, title: "Other")
        let browser = TabController(
            session: BrowserSession(tabs: [pinned, other], selectedTabID: pinned.id),
            settings: BrowserSettings(), logger: SilentLogger()
        )
        return (browser, pinned.id, other.id)
    }

    @Test("Closing a pin keeps it pinned and moves the selection off it")
    func closeKeepsPin() throws {
        let (browser, pinned, other) = controller()
        browser.close(pinned)
        let tab = try #require(browser.tabs.first { $0.id == pinned })
        #expect(tab.isPinned)
        #expect(tab.isHibernated)
        #expect(browser.selectedID == other)
        #expect(!browser.canReopen)
    }

    @Test("Closing a pin that wandered off returns it to its pinned page")
    func closeResetsToPinnedPage() throws {
        let (browser, pinned, _) = controller()
        browser.close(pinned)
        let tab = try #require(browser.tabs.first { $0.id == pinned })
        #expect(tab.url == home)
        #expect(tab.snapshot.url == home)
        #expect(tab.snapshot.title.isEmpty)
        #expect(tab.snapshot.faviconData == nil)
        #expect(tab.snapshot.pinnedPageElsewhere == nil)
    }
}

private struct SilentLogger: EventLogging {
    func debug(_ message: @autoclosure () -> String) {}
    func notice(_ message: @autoclosure () -> String) {}
    func error(_ message: @autoclosure () -> String) {}
}
