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
        let url = try await server.start()
        let storage = UnlockPendingStorage()
        let registry = BrowsingContextRegistry(sessionCookies: storage)
        let controller = TabController(
            session: BrowserSession(tabs: [TabSnapshot(url: url)], selectedTabID: nil),
            settings: BrowserSettings(), logger: SilentGraceLogger(), contexts: registry
        )
        let tab = try #require(controller.webTabs.first)

        tab.wake(loading: nil)
        #expect(try await settles { server.pageRequestCount == 1 })

        await storage.unlock()
        #expect(try await settles { server.pageRequestCount == 2 })
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
