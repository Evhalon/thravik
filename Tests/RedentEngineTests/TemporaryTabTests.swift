import Foundation
import RedentKit
import Testing
@testable import RedentEngine

@Suite("Temporary tabs")
@MainActor
struct TemporaryTabTests {
    private func controller() -> TabController {
        var tab = TabSnapshot(title: "Normal")
        tab.spaceID = BrowserSpace.workID
        return TabController(session: BrowserSession(tabs: [tab], selectedTabID: tab.id),
                             settings: BrowserSettings(), logger: MuteLogger())
    }

    @Test("A temporary tab browses in its own ephemeral context")
    func ownsEphemeralContext() throws {
        let browser = controller()
        let tab = browser.newTemporaryTab(url: nil, expiresAt: nil)
        #expect(tab.snapshot.browsingContext.isEphemeral)
        #expect(browser.contexts.tabCount(for: tab.snapshot.browsingContext) == 1)
    }

    @Test("Closing a temporary tab releases its store and leaves no reopen record")
    func closingCleansUp() throws {
        let browser = controller()
        let tab = browser.newTemporaryTab(url: nil, expiresAt: nil)
        let context = tab.snapshot.browsingContext
        browser.close(tab.id)

        #expect(browser.contexts.tabCount(for: context) == 0)
        #expect(!browser.contexts.isLoaded(context))
        #expect(!browser.canReopen)
    }

    @Test("A temporary tab is absent from the session that gets persisted")
    func excludedFromSnapshot() throws {
        let browser = controller()
        let tab = browser.newTemporaryTab(url: nil, expiresAt: nil)
        let snapshot = WorkspaceSnapshot(session: browser.session)
        #expect(!snapshot.tabs.contains { $0.id == tab.id })
    }

    @Test("Keeping a tab moves it out of the ephemeral store into its Container")
    func keepPromotes() throws {
        let browser = controller()
        let tab = browser.newTemporaryTab(url: nil, expiresAt: nil)
        let ephemeral = tab.snapshot.browsingContext
        browser.keepTab(tab.id)

        #expect(!tab.snapshot.isTemporary)
        #expect(tab.snapshot.browsingContext == .container(BrowserContainer.defaultID))
        #expect(browser.contexts.tabCount(for: ephemeral) == 0)
    }

    @Test("An expired background tab closes; the one on screen is offered instead")
    func sweepFollowsPolicy() throws {
        let browser = controller()
        let past = Date(timeIntervalSince1970: 1)
        let background = browser.newTemporaryTab(url: nil, expiresAt: past)
        let selected = browser.newTemporaryTab(url: nil, expiresAt: past)
        browser.select(selected.id)

        let prompted = browser.sweepExpiredTabs(now: .now)
        #expect(prompted == selected.id)
        #expect(!browser.tabs.contains { $0.id == background.id })
        #expect(browser.tabs.contains { $0.id == selected.id })
    }
}

private struct MuteLogger: EventLogging {
    func debug(_ message: @autoclosure () -> String) {}
    func notice(_ message: @autoclosure () -> String) {}
    func error(_ message: @autoclosure () -> String) {}
}
