import Foundation
import Testing
@testable import RedentKit

@Suite("Link activation")
struct LinkActivationTests {
    @Test("A plain click stays in the tab")
    func plainClick() {
        #expect(!LinkActivation.opensNewTab(isUserLink: true, commandHeld: false))
    }

    @Test("Command-click on a link opens a new tab")
    func commandClick() {
        #expect(LinkActivation.opensNewTab(isUserLink: true, commandHeld: true))
    }

    @Test("Command held during a redirect does not spawn a tab")
    func commandDuringRedirect() {
        #expect(!LinkActivation.opensNewTab(isUserLink: false, commandHeld: true))
    }
}
