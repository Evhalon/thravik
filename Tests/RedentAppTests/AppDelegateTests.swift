import AppKit
import Foundation
import Testing
@testable import Redent

@Suite("External links from native apps")
struct AppDelegateTests {
    @MainActor
    @Test("Receiving a Teams-style web link presents the browser window")
    func externalLinkPresentsBrowserWindow() throws {
        let delegate = AppDelegate()
        var presentationCount = 0
        delegate.presentApplication = { presentationCount += 1 }
        let link = try #require(URL(string: "https://teams.microsoft.com/l/message/example"))

        delegate.application(NSApplication.shared, open: [link])

        #expect(presentationCount == 1)
    }
}
