import Testing
@testable import RedentUI

@Suite("Window presentation")
@MainActor
struct BrowserPresentationTests {
    /// Quitting from the Settings sheet used to leave this binding set, so
    /// SwiftUI re-presented the sheet every time AppKit ended it and the app
    /// never terminated.
    @Test("Nothing stays presented once the window dismisses its modals")
    func clearsEveryPresentation() {
        let model = makeTestBrowserModel()
        model.sheet = .settings
        model.showCommands()

        model.dismissPresentations()

        #expect(model.sheet == nil)
        #expect(!model.showsCommandBar)
    }
}
