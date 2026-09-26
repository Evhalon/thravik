import Foundation
import RedentKit
import Testing
import WebKit
@testable import RedentEngine

/// A Keychain waiting on an unlock dialog used to hold the first page back for
/// as long as the dialog stayed up.
@Suite("First load while the Keychain is locked")
@MainActor
struct FirstLoadGraceTests {
    @Test("The first page loads without waiting for a slow restore, then reloads signed in")
    func loadsThenReloads() async throws {
        let server = try SignedOutMediaServer(video: Data())
        defer { server.stop() }
        let (controller, storage) = try await makeController(url: server.start())
        let tab = try #require(controller.webTabs.first)

        tab.wake(loading: nil)
        #expect(try await settles { server.pageRequestCount == 1 })
        #expect(try await settles { tab.webView?.backForwardList.currentItem != nil })

        await storage.unlock()
        #expect(try await settles { server.pageRequestCount == 2 })
    }

    /// `reload()` does nothing before a page commits, so an unlock landing
    /// while the first page was still on its way used to lose the sign-ins.
    @Test("An unlock before the first page commits still loads it signed in")
    func unlockBeforeCommitLoadsAgain() async throws {
        let server = try SignedOutMediaServer(video: Data(), responseDelay: .seconds(2))
        defer { server.stop() }
        let (controller, storage) = try await makeController(url: server.start())
        let tab = try #require(controller.webTabs.first)

        tab.wake(loading: nil)
        #expect(try await settles { server.pageRequestCount == 1 })
        #expect(tab.webView?.backForwardList.currentItem == nil)

        await storage.unlock()
        #expect(try await settles { server.pageRequestCount == 2 })
    }

    private func makeController(url: URL) -> (TabController, UnlockPendingStorage) {
        let storage = UnlockPendingStorage()
        let controller = TabController(
            session: BrowserSession(tabs: [TabSnapshot(url: url)], selectedTabID: nil),
            settings: BrowserSettings(), logger: SilentGraceLogger(),
            contexts: BrowsingContextRegistry(sessionCookies: storage)
        )
        return (controller, storage)
    }

    private func settles(_ condition: () -> Bool) async throws -> Bool {
        for _ in 0..<250 {
            if condition() { return true }
            try await Task.sleep(for: .milliseconds(20))
        }
        return false
    }
}

/// Answers `load` only once `unlock()` is called, like a Keychain read behind
/// an "Always Allow" dialog.
private actor UnlockPendingStorage: SessionCookieStoring {
    private var waiting: [CheckedContinuation<Void, Never>] = []
    private var isUnlocked = false

    func load(container: UUID) async -> [StoredCookie] {
        if !isUnlocked { await withCheckedContinuation { waiting.append($0) } }
        return []
    }

    func unlock() {
        isUnlocked = true
        waiting.forEach { $0.resume() }
        waiting.removeAll()
    }

    func save(_ cookies: [StoredCookie], container: UUID) {}
    func remove(container: UUID) {}
}

private struct SilentGraceLogger: EventLogging {
    func debug(_ message: @autoclosure () -> String) {}
    func notice(_ message: @autoclosure () -> String) {}
    func error(_ message: @autoclosure () -> String) {}
}
