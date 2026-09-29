import Foundation
import Testing
@testable import RedentEngine

@MainActor
@Suite struct WebInspectorTapTests {
    /// WebKit suspended the hidden Web Inspector within seconds, and every
    /// console message after that waited until something else woke it.
    @Test func consoleMessagesStillArriveAfterTheTapSitsIdle() async throws {
        let tab = try await FindTestPage.saying("<p>idle</p>")
        let page = try #require(tab.webView)
        let tap = WebInspectorTap(webView: page)
        var received: [String] = []
        tap.onMessage = { received.append($0) }
        try await tap.attach()
        defer { tap.detach() }
        tap.send(#"{"id":1,"method":"Runtime.enable","params":{}}"#)

        try await Task.sleep(for: .seconds(5))
        _ = try? await page.evaluateJavaScript("console.log('after-idle')")

        let deadline = ContinuousClock.now + .seconds(3)
        while ContinuousClock.now < deadline, !received.contains(where: { $0.contains("after-idle") }) {
            try await Task.sleep(for: .milliseconds(20))
        }
        #expect(received.contains { $0.contains("after-idle") })
    }
}
