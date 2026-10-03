import Testing
@testable import RedentEngine

@Suite("Native find across frames", .serialized)
@MainActor
struct FindFrameTests {
    @Test("A child frame receives native search and clears when find closes")
    func findsAndClearsChildFrame() async throws {
        let tab = try await FindTestPage.saying("<p>outside</p><iframe srcdoc='<p>frame needle text</p>'></iframe>")
        #expect(await tab.findInPage("needle", forward: true) == .foundWithoutCount)
        let view = try #require(tab.webView)
        let frame = try #require(tab.pageFinder.frames.frame(at: [0]))
        let script = "return String(window.getSelection())"
        let selected = try await view.callAsyncJavaScript(script, in: frame, contentWorld: PageScripts.contentWorld) as? String
        #expect(selected == "needle")
        tab.clearFindHighlight()
        let deadline = ContinuousClock.now + .seconds(5)
        var remaining: String?
        repeat {
            try await Task.sleep(for: .milliseconds(20))
            remaining = try await view.callAsyncJavaScript(script, in: frame, contentWorld: PageScripts.contentWorld) as? String
        } while remaining != "" && ContinuousClock.now < deadline
        #expect(remaining == "")
    }
}
