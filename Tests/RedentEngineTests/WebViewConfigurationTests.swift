import Foundation
import Testing
import WebKit
@testable import RedentEngine

@Suite("Web view configuration")
@MainActor
struct WebViewConfigurationTests {
    private func makeView() -> WKWebView {
        WebViewFactory.makeWebView(configuration: WebViewFactory.makeConfiguration(
            store: .nonPersistent(), blocksTrackers: false, contentBlocker: nil
        ))
    }

    @Test("A page can actually use the Fullscreen API")
    func pagesCanGoFullscreen() async throws {
        let view = makeView()
        view.loadHTMLString("<html><body><video></video></body></html>",
                            baseURL: URL(string: "https://example.com"))
        try await waitUntil("!!document.body", in: view)

        let enabled = try await view.evaluateJavaScript("document.fullscreenEnabled") as? Bool
        #expect(enabled == true)
    }

    @Test("A video element exposes a way into fullscreen")
    func videoExposesFullscreenEntry() async throws {
        let view = makeView()
        view.loadHTMLString("<html><body><video id=v></video></body></html>",
                            baseURL: URL(string: "https://example.com"))
        try await waitUntil("!!document.getElementById('v')", in: view)

        let hasRequest = try await view.evaluateJavaScript(
            "typeof document.getElementById('v').requestFullscreen === 'function'"
        ) as? Bool
        #expect(hasRequest == true)
    }

    @Test("An off-screen tab is suspended rather than left running")
    func idleTabsSuspend() {
        let configuration = WebViewFactory.makeConfiguration(
            store: .nonPersistent(), blocksTrackers: false, contentBlocker: nil
        )
        #expect(configuration.preferences.inactiveSchedulingPolicy == .suspend)
    }

    @Test("Media can start without another click, so YouTube ads cannot stall the player")
    func mediaDoesNotNeedAGesture() {
        let configuration = WebViewFactory.makeConfiguration(
            store: .nonPersistent(), blocksTrackers: false, contentBlocker: nil
        )
        #expect(configuration.mediaTypesRequiringUserActionForPlayback.isEmpty)
    }

    /// Polls a condition in the page. `document.readyState` is no use here: for
    /// a moment after a load starts it still describes the previous, empty
    /// document and reports "complete".
    private func waitUntil(_ javaScript: String, in view: WKWebView) async throws {
        for _ in 0..<150 {
            if let ready = try? await view.evaluateJavaScript(javaScript) as? Bool, ready { return }
            try await Task.sleep(for: .milliseconds(20))
        }
        Issue.record("The page never reached: \(javaScript)")
    }
}
