import Foundation
import RedentKit
import Testing
import WebKit
@testable import RedentEngine

/// A real tab showing a small page, once the find script has reached it.
@MainActor
enum FindTestPage {
    static func saying(_ body: String, head: String = "") async throws -> WebTab {
        let controller = TabController(
            session: BrowserSession(tabs: [TabSnapshot()], selectedTabID: nil),
            settings: BrowserSettings(),
            logger: QuietFindLogger()
        )
        let tab = try #require(controller.webTabs.first)
        tab.wake(loading: nil)
        let view = try #require(tab.webView)
        // A real viewport, so a match can be off screen and need revealing.
        view.frame = CGRect(x: 0, y: 0, width: 800, height: 600)
        view.loadHTMLString("<head>\(head)</head><body>\(body)</body>", baseURL: URL(string: "https://example.com"))
        for _ in 0..<200 {
            let ready = try? await view.callAsyncJavaScript(
                "return typeof window.redentFind === 'function' && !!document.body",
                in: nil,
                contentWorld: PageScripts.contentWorld
            ) as? Bool
            if ready == true { return tab }
            try await Task.sleep(for: .milliseconds(20))
        }
        Issue.record("The find script never reached the page")
        return tab
    }
}

private struct QuietFindLogger: EventLogging {
    func debug(_ message: @autoclosure () -> String) {}
    func notice(_ message: @autoclosure () -> String) {}
    func error(_ message: @autoclosure () -> String) {}
}
