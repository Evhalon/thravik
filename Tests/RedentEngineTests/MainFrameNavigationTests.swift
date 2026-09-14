import Testing
@testable import RedentEngine

@Suite("Main-frame navigation")
@MainActor
struct MainFrameNavigationTests {
    @Test("Iframe navigations do not update their parent tab")
    func iframeNavigationIsNotTracked() {
        #expect(!WebTabNavigationDelegate.tracksTab(targetFrameIsMain: false))
    }

    @Test("A new window target does not update its opener tab")
    func unboundTargetIsNotTracked() {
        #expect(!WebTabNavigationDelegate.tracksTab(targetFrameIsMain: nil))
    }

    @Test("The main document updates its tab")
    func mainFrameIsTracked() {
        #expect(WebTabNavigationDelegate.tracksTab(targetFrameIsMain: true))
    }
}
