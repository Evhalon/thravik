import Foundation
import RedentKit
import Testing
import WebKit
@testable import RedentEngine

/// Regression cover for Octane attachments that would not play: the player's
/// own requests came back as a sign-in page while the page's fetches were
/// signed in.
@Suite("Media rescue")
@MainActor
final class MediaRescueTests {
    private var windows: [NSWindow] = []

    deinit {
        MainActor.assumeIsolated { windows.forEach { $0.close() } }
    }

    @Test("A video the player was refused plays from the page's own fetch")
    func rescuesSignedOutVideo() async throws {
        let server = try SignedOutMediaServer(video: try Self.clip())
        defer { server.stop() }
        let tab = try await open(try await server.start())

        #expect(try await settles(tab, "v.currentSrc.startsWith('blob:') && v.readyState >= 1"))
    }

    @Test("A file the page cannot fetch either is left as it failed")
    func leavesUnfetchableVideo() async throws {
        let server = try SignedOutMediaServer(video: try Self.clip(), servesVideoToFetch: false)
        defer { server.stop() }
        let tab = try await open(try await server.start())

        #expect(try await settles(tab, "v.error !== null"))
        try await Task.sleep(for: .milliseconds(300))
        #expect(try await pageValue(tab, "v.currentSrc.startsWith('http:')") as? Bool == true)
    }

    private static func clip() throws -> Data {
        let url = try #require(Bundle.module.url(forResource: "clip", withExtension: "mp4", subdirectory: "Fixtures"))
        return try Data(contentsOf: url)
    }

    private func open(_ url: URL) async throws -> WebTab {
        let controller = TabController(
            session: BrowserSession(tabs: [TabSnapshot()], selectedTabID: nil),
            settings: BrowserSettings(),
            logger: SilentRescueLogger()
        )
        let tab = try #require(controller.webTabs.first)
        tab.wake(loading: url)
        // WebKit holds a player's loading back until its page is on screen.
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 150),
            styleMask: [.titled], backing: .buffered, defer: false
        )
        window.isReleasedWhenClosed = false
        window.contentView = tab.webView
        window.orderFrontRegardless()
        windows.append(window)
        return tab
    }

    /// Loading and fetching take real round trips; poll rather than guess a delay.
    private func settles(_ tab: WebTab, _ condition: String) async throws -> Bool {
        for _ in 0..<250 {
            if (try? await pageValue(tab, condition)) as? Bool == true { return true }
            try await Task.sleep(for: .milliseconds(20))
        }
        return false
    }

    private func pageValue(_ tab: WebTab, _ expression: String) async throws -> Any? {
        try await tab.webView?.callAsyncJavaScript("return \(expression)", in: nil, contentWorld: .page)
    }
}

private struct SilentRescueLogger: EventLogging {
    func debug(_ message: @autoclosure () -> String) {}
    func notice(_ message: @autoclosure () -> String) {}
    func error(_ message: @autoclosure () -> String) {}
}
