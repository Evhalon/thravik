import Foundation
import RedentKit
import Testing
@testable import RedentEngine

@Suite("Tab emoji persistence")
@MainActor
struct TabCustomEmojiPersistenceTests {
    @Test("A saved session restores the emoji onto the live tab")
    func sessionRestoresEmoji() {
        var snapshot = TabSnapshot(url: URL(string: "https://example.com"), title: "Example")
        snapshot.customEmoji = "🔥"
        let browser = controller(session: BrowserSession(tabs: [snapshot], selectedTabID: snapshot.id))
        #expect(browser.webTabs.first?.snapshot.customEmoji == "🔥")
        #expect(browser.session.tabs.first?.customEmoji == "🔥")
    }

    @Test("Setting an emoji writes through to the published session")
    func setEmojiUpdatesSession() throws {
        let browser = controller()
        let tab = browser.newTab(url: URL(string: "https://example.com"))
        tab.setCustomEmoji("🎉")
        #expect(tab.snapshot.customEmoji == "🎉")
        #expect(browser.session.tabs.contains { $0.id == tab.id && $0.customEmoji == "🎉" })
        tab.setCustomEmoji("nope")
        #expect(tab.snapshot.customEmoji == "🎉")
        tab.setCustomEmoji(nil)
        #expect(tab.snapshot.customEmoji == nil)
    }

    @Test("Hibernation leaves the emoji on the snapshot")
    func hibernateKeepsEmoji() throws {
        let browser = controller()
        let opened = browser.newTab(url: URL(string: "https://example.com"))
        let tab = try #require(browser.webTabs.first { $0.id == opened.id })
        tab.setCustomEmoji("🔥")
        tab.wake(loading: URL(string: "https://example.com"))
        tab.hibernate()
        #expect(tab.isHibernated)
        #expect(tab.snapshot.customEmoji == "🔥")
    }

    private func controller(session: BrowserSession = BrowserSession()) -> TabController {
        TabController(session: session, settings: BrowserSettings(), logger: EmojiLogger())
    }
}

private struct EmojiLogger: EventLogging {
    func debug(_ message: @autoclosure () -> String) {}
    func notice(_ message: @autoclosure () -> String) {}
    func error(_ message: @autoclosure () -> String) {}
}
