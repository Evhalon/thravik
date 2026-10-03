import Foundation
import RedentKit
import Testing
@testable import RedentEngine

@Suite("Background tabs")
@MainActor
struct BackgroundTabTests {
    @Test("A background tab joins the current Space without taking selection")
    func keepsSelection() throws {
        let browser = TabController(session: BrowserSession(), settings: BrowserSettings(), logger: BackgroundTabLogger())
        let reading = browser.newTab(url: nil)
        let url = try #require(URL(string: "https://example.com"))

        let opened = browser.newBackgroundTab(url: url)

        #expect(browser.selectedID == reading.id)
        #expect(browser.tabs.contains { $0.id == opened.id })
        #expect(opened.snapshot.spaceID == browser.session.selectedSpaceID)
    }

    @Test("A private window's background tab stays in its ephemeral session")
    func privateWindow() throws {
        let browser = TabController(
            session: BrowserSession(), settings: BrowserSettings(), logger: BackgroundTabLogger(), privateSessionID: UUID()
        )
        let reading = browser.newTab(url: nil)
        let opened = browser.newBackgroundTab(url: try #require(URL(string: "https://example.com")))
        #expect(opened.snapshot.browsingContext == reading.snapshot.browsingContext)
        #expect(opened.snapshot.browsingContext.isEphemeral)
    }
}

private struct BackgroundTabLogger: EventLogging {
    func debug(_ message: @autoclosure () -> String) {}
    func notice(_ message: @autoclosure () -> String) {}
    func error(_ message: @autoclosure () -> String) {}
}
