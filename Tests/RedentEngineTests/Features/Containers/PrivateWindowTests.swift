import Foundation
import RedentKit
import Testing
@testable import RedentEngine

@Suite("Private windows")
@MainActor
struct PrivateWindowTests {
    private func controller(
        privateSessionID: UUID? = nil, contexts: BrowsingContextRegistry = BrowsingContextRegistry()
    ) -> TabController {
        TabController(
            session: BrowserSession(),
            settings: BrowserSettings(),
            logger: QuietLogger(),
            contexts: contexts,
            privateSessionID: privateSessionID
        )
    }

    @Test("Every tab in a private window shares one ephemeral session")
    func tabsShareOneEphemeralSession() {
        let browser = controller(privateSessionID: UUID())
        #expect(browser.isPrivate)

        let first = browser.newTab(url: nil)
        let second = browser.newTab(url: nil)
        #expect(first.snapshot.browsingContext.isEphemeral)
        #expect(first.snapshot.browsingContext == second.snapshot.browsingContext)
        #expect(browser.contexts.tabCount(for: first.snapshot.browsingContext) == 2)
    }

    @Test("A private tab is excluded from the saved workspace and the reopen stack")
    func nothingOutlivesTheWindow() {
        let browser = controller(privateSessionID: UUID())
        let tab = browser.newTab(url: URL(string: "https://example.com"))
        let context = tab.snapshot.browsingContext
        browser.close(tab.id)

        #expect(!browser.canReopen)
        #expect(WorkspaceSnapshot(session: browser.session).tabs.isEmpty)
        #expect(!browser.contexts.isLoaded(context))
    }

    @Test("Closing the window releases its ephemeral store")
    func retiringReleasesTheStore() {
        let browser = controller(privateSessionID: UUID())
        let context = browser.newTab(url: nil).snapshot.browsingContext
        _ = browser.contexts.store(for: context)
        #expect(browser.contexts.isLoaded(context))

        browser.retire()
        #expect(!browser.contexts.isLoaded(context))
    }

    @Test("An ordinary window opens ordinary tabs")
    func ordinaryWindowsAreUnaffected() {
        let browser = controller()
        #expect(!browser.isPrivate)
        #expect(!browser.newTab(url: nil).snapshot.browsingContext.isEphemeral)
    }

    @Test("One window re-counting its tabs cannot drop another window's store")
    func windowsDoNotEvictEachOther() {
        let shared = BrowsingContextRegistry()
        let first = controller(privateSessionID: UUID(), contexts: shared)
        let second = controller(privateSessionID: UUID(), contexts: shared)
        let kept = second.newTab(url: nil).snapshot.browsingContext
        _ = shared.store(for: kept)

        // The first window mutating its own tabs re-syncs the whole registry.
        let throwaway = first.newTab(url: nil)
        first.close(throwaway.id)

        #expect(shared.isLoaded(kept))
        #expect(shared.tabCount(for: kept) == 1)
    }

    @Test("Two windows in the same Container share its store")
    func containersAreSharedAcrossWindows() {
        let shared = BrowsingContextRegistry()
        let first = controller(contexts: shared)
        let second = controller(contexts: shared)
        let context = BrowsingContext.container(BrowserContainer.defaultID)

        #expect(first.contexts.store(for: context) === second.contexts.store(for: context))
    }
}

private struct QuietLogger: EventLogging {
    func debug(_ message: @autoclosure () -> String) {}
    func notice(_ message: @autoclosure () -> String) {}
    func error(_ message: @autoclosure () -> String) {}
}
