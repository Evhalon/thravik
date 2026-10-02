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

    @Test("Closing a pin with only pins remaining clears selection", arguments: [1, 2])
    func closeWithOnlyPins(count: Int) throws {
        let pins = (0..<count).map { _ in TabSnapshot(url: home, isPinned: true) }
        let selected = try #require(pins.first?.id)
        let browser = TabController(
            session: BrowserSession(tabs: pins, selectedTabID: selected),
            settings: BrowserSettings(), logger: SilentLogger()
        )
        browser.close(selected)
        #expect(browser.selectedID == nil)
        #expect(browser.selectedTab == nil)
        #expect(browser.session.selectedTabID == nil)
        #expect(browser.tabs.count == count)
        #expect(browser.tabs.allSatisfy { $0.isPinned })
        browser.select(selected)
        #expect(browser.selectedID == selected)
        browser.close(selected)
        #expect(browser.selectedID == nil)
    }

    @Test("Closing the last normal tab does not select a saved pin")
    func closeLastNormalTab() {
        let (browser, pinned, other) = controller()
        browser.select(other)
        browser.close(other)
        #expect(browser.selectedID == nil)
        #expect(browser.tabs.map(\.id) == [pinned])
    }

    @Test("Closing an unselected pin preserves the selected pin")
    func closeUnselectedPin() {
        let (browser, pinned, other) = controller()
        browser.togglePin(other)
        browser.close(other)
        #expect(browser.selectedID == pinned)
        #expect(browser.tabs.count == 2)
    }
}

private struct SilentLogger: EventLogging {
    func debug(_ message: @autoclosure () -> String) {}
    func notice(_ message: @autoclosure () -> String) {}
    func error(_ message: @autoclosure () -> String) {}
}
