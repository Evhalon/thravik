import Foundation
import RedentKit
import Testing
@testable import RedentUI

// @unchecked Sendable: the lock protects every read and write to saved sessions.
private final class RecordingSessionStore: SessionStoring, @unchecked Sendable {
    private let lock = NSLock()
    private var sessions: [BrowserSession] = []
    var saved: [BrowserSession] { lock.withLock { sessions } }

    func load() -> BrowserSession { BrowserSession() }
    func save(_ session: BrowserSession) { lock.withLock { sessions.append(session) } }
}

@MainActor
@Suite("Browser session persistence")
struct BrowserSessionPersistenceTests {
    @Test("Closing a tab immediately saves only the tabs still open")
    func closedTabIsNotRestored() {
        let first = TabSnapshot(url: URL(string: "https://first.example"))
        let second = TabSnapshot(url: URL(string: "https://second.example"))
        let browser = FakeBrowser()
        browser.stubTabs = [InertTab(), InertTab()]
        browser.session = BrowserSession(tabs: [first, second], selectedTabID: first.id)
        let store = RecordingSessionStore()
        let model = makeTestBrowserModel(tabs: browser, session: store)

        browser.stubTabs.removeLast()
        browser.session.tabs.removeLast()
        browser.onChange?()

        #expect(store.saved.count == 1)
        #expect(store.saved.first?.tabs.map(\.id) == [first.id])
        withExtendedLifetime(model) {}
    }

    @Test("Navigation changes retain the periodic save policy")
    func navigationDoesNotForceSave() {
        let browser = FakeBrowser()
        browser.stubTabs = [InertTab()]
        let store = RecordingSessionStore()
        let model = makeTestBrowserModel(tabs: browser, session: store)

        browser.onChange?()

        #expect(store.saved.isEmpty)
        withExtendedLifetime(model) {}
    }
}
