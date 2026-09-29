import AppKit
import Foundation
import Testing
import WebKit
@testable import RedentEngine

/// What the docked frontend needs from WebKit that Chrome has built in.
@MainActor
@Suite struct DevToolsFrontendHostTests {
    /// Tree rows in the Console and the Network panel ask the shadow root for
    /// its selection before toggling: without it a single click on an
    /// accordion threw and only a double click got through. Idle callbacks
    /// and background tasks are called just as unchecked.
    @Test func theFrontendFindsTheChromeOnlyAPIsItCallsUnchecked() async throws {
        let tab = try await FindTestPage.saying("<p>x</p>")
        let page = try #require(tab.webView)
        let panel = try #require(DevToolsPanel(inspecting: page))
        defer { panel.close() }
        panel.open()
        let probe = "typeof ShadowRoot.prototype.getSelection === 'function'"
            + " && typeof requestIdleCallback === 'function' && typeof scheduler.postTask === 'function'"
        let deadline = ContinuousClock.now + .seconds(10)
        var ready = false
        while !ready, ContinuousClock.now < deadline {
            ready = (try? await panel.frontend.evaluateJavaScript(probe) as? Bool) == true
            if !ready { try await Task.sleep(for: .milliseconds(50)) }
        }
        #expect(ready)
    }
}
