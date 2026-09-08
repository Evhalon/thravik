import Foundation
import Testing
@testable import RedentKit

@Suite("Link activation")
struct LinkActivationTests {
    @Test("A plain click stays in the tab")
    func plainClick() {
        #expect(LinkActivation.target(isUserLink: true, commandHeld: false, shiftHeld: false) == .currentTab)
    }

    @Test("Command-click opens a tab behind the current page")
    func commandClick() {
        #expect(LinkActivation.target(isUserLink: true, commandHeld: true, shiftHeld: false) == .backgroundTab)
    }

    @Test("Command-shift-click opens the tab and goes there")
    func commandShiftClick() {
        #expect(LinkActivation.target(isUserLink: true, commandHeld: true, shiftHeld: true) == .foregroundTab)
    }

    @Test("Command held during a redirect does not spawn a tab")
    func commandDuringRedirect() {
        #expect(LinkActivation.target(isUserLink: false, commandHeld: true, shiftHeld: false) == .currentTab)
    }
}
