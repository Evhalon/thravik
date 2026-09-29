import Foundation
import RedentKit
import Testing
import WebKit
@testable import RedentEngine

/// Reader and mute against a real web view: both live in injected scripts, so
/// a missing resource or a renamed global only shows up here.
@Suite("Reader and mute")
@MainActor
struct ReaderAndMuteTests {
    private static let article = String(repeating: "<p>A long paragraph of real prose, with commas, clauses, and enough words to read like an article body.</p>", count: 12)

    @Test("An article opens in Reader and closes back to the page as it was")
    func readerRoundTrip() async throws {
        let tab = try await page("<nav><a href='/'>Home</a></nav><article><h1>Title</h1>\(Self.article)</article>")

        await tab.toggleReader()
        #expect(tab.isReaderActive)
        #expect(try await pageValue(tab, "!!document.getElementById('redent-reader-host')") as? Bool == true)
        #expect(try await pageValue(tab, "document.documentElement.style.overflow") as? String == "hidden")

        await tab.toggleReader()
        #expect(!tab.isReaderActive)
        #expect(try await pageValue(tab, "!!document.getElementById('redent-reader-host')") as? Bool == false)
        #expect(try await pageValue(tab, "document.documentElement.style.overflow") as? String == "")
    }

    @Test("The page cannot reach into the Reader overlay")
    func overlayIsClosed() async throws {
        let tab = try await page("<article>\(Self.article)</article>")
        await tab.toggleReader()
        #expect(try await pageValue(tab, "document.getElementById('redent-reader-host').shadowRoot === null") as? Bool == true)
    }

    @Test("A page with no article stays as it is")
    func noArticle() async throws {
        let tab = try await page("<p>Short.</p>")
        await tab.toggleReader()
        #expect(!tab.isReaderActive)
    }

    @Test("Muting reaches the page's media and unmuting hands it back")
    func muteRoundTrip() async throws {
        let tab = try await page("<audio id='a'></audio><video id='v'></video>")
        tab.setMuted(true)
        #expect(try await settles(tab, "a.muted && v.muted"))

        tab.setMuted(false)
        #expect(try await settles(tab, "!a.muted && !v.muted"))
    }

    @Test("Unmuting leaves media the page muted itself alone")
    func respectsPageMute() async throws {
        let tab = try await page("<video id='v' muted></video>")
        tab.setMuted(true)
        tab.setMuted(false)
        // Evaluations run in order, so once the unmute has landed a check queued
        // behind it sees the final state.
        #expect(try await settles(tab, "v.muted"))
    }

    @Test("Tab volume scales the page's own level, and 100% hands it back")
    func volumeScalesPageLevel() async throws {
        let tab = try await page("<audio id='a'></audio>")
        tab.setVolume(0.5)
        #expect(try await settles(tab, "Math.abs(a.volume - 0.5) < 0.001"))

        _ = try await pageValue(tab, "(a.volume = 0.8, true)")
        #expect(try await settles(tab, "Math.abs(a.volume - 0.4) < 0.001"))

        tab.setVolume(1)
        #expect(try await settles(tab, "Math.abs(a.volume - 0.8) < 0.001"))
    }

    /// The mute is fire-and-forget, so poll the page rather than guess a delay.
    private func settles(_ tab: WebTab, _ condition: String) async throws -> Bool {
        for _ in 0..<100 {
            if try await pageValue(tab, condition) as? Bool == true { return true }
            try await Task.sleep(for: .milliseconds(20))
        }
        return false
    }

    private func pageValue(_ tab: WebTab, _ expression: String) async throws -> Any? {
        try await tab.webView?.callAsyncJavaScript("return \(expression)", in: nil, contentWorld: .page)
    }

    private func page(_ body: String) async throws -> WebTab {
        let controller = TabController(
            session: BrowserSession(tabs: [TabSnapshot()], selectedTabID: nil),
            settings: BrowserSettings(),
            logger: QuietReaderLogger()
        )
        let tab = try #require(controller.webTabs.first)
        tab.wake(loading: nil)
        let view = try #require(tab.webView)
        view.loadHTMLString("<body>\(body)</body>", baseURL: URL(string: "https://example.com"))
        for _ in 0..<200 {
            let ready = try? await view.callAsyncJavaScript(
                "return typeof window.redentToggleReader === 'function' && typeof window.redentSetAudio === 'function'",
                in: nil,
                contentWorld: PageScripts.contentWorld
            ) as? Bool
            if ready == true { return tab }
            try await Task.sleep(for: .milliseconds(20))
        }
        Issue.record("The reader and media scripts never reached the page")
        return tab
    }
}

private struct QuietReaderLogger: EventLogging {
    func debug(_ message: @autoclosure () -> String) {}
    func notice(_ message: @autoclosure () -> String) {}
    func error(_ message: @autoclosure () -> String) {}
}
