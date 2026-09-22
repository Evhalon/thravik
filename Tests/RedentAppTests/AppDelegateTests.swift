import AppKit
import Foundation
import Testing
@testable import Redent

@Suite("External links from native apps")
struct AppDelegateTests {
    @MainActor
    @Test("Receiving a Teams-style web link activates the browser")
    func externalLinkActivatesBrowser() throws {
        let delegate = AppDelegate()
        var activationCount = 0
        delegate.activateApplication = { activationCount += 1 }
        let link = try #require(URL(string: "https://teams.microsoft.com/l/message/example"))

        delegate.application(NSApplication.shared, open: [link])

        #expect(activationCount == 1)
    }
}
