import AppKit
import Foundation
import RedentKit
import Testing
import WebKit
@testable import RedentEngine

@MainActor
final class FloatingVideoFixture {
    let browser: TabController
    let tab: WebTab
    let view: WKWebView
    let window: NSWindow

    init() async throws {
        var settings = BrowserSettings()
        settings.hibernation = .aggressive
        browser = TabController(session: BrowserSession(), settings: settings, logger: SilentVideoLogger())
        tab = try #require(browser.newTab(url: nil) as? WebTab)
        tab.wake(loading: nil)
        view = try #require(tab.webView)
        window = NSWindow(contentRect: NSRect(x: 100, y: 100, width: 640, height: 360),
                          styleMask: [.titled], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = WebViewContainer()
        (window.contentView as? WebViewContainer)?.attach(view)
        window.orderFrontRegardless()
        let fixture = try #require(Bundle.module.url(
            forResource: "clip", withExtension: "mp4", subdirectory: "Fixtures"
        ))
        let encoded = try Data(contentsOf: fixture).base64EncodedString()
        view.loadHTMLString("""
        <main style="transform:translateZ(0);overflow:hidden">
        <video style="opacity:0.9" autoplay muted loop src="data:video/mp4;base64,\(encoded)"></video>
        </main>
        """, baseURL: URL(string: "https://video.example"))
        #expect(await settles { self.tab.canFloatVideo && !self.view.isLoading })
        #expect(await view.requestMediaPlaybackState() == .playing)
    }

    func close() { browser.retire(); window.close() }

    func value(_ expression: String) async throws -> Any? {
        try await view.callAsyncJavaScript("return \(expression)", in: nil, contentWorld: PageScripts.contentWorld)
    }

    func settles(_ condition: () -> Bool) async -> Bool {
        for _ in 0..<250 {
            if condition() { return true }
            try? await Task.sleep(for: .milliseconds(20))
        }
        return false
    }
}

private struct SilentVideoLogger: EventLogging {
    func debug(_ message: @autoclosure () -> String) {}
    func notice(_ message: @autoclosure () -> String) {}
    func error(_ message: @autoclosure () -> String) {}
}
