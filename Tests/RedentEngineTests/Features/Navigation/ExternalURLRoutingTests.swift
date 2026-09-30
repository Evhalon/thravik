import Foundation
import Testing
@testable import RedentEngine

@Suite("External URL routing")
@MainActor
struct ExternalURLRoutingTests {
    @Test("App sign-in callbacks leave the browser", arguments: [
        "claude://login/callback?code=x", "zoommtg://zoom.us/join", "mailto:someone@example.com", "SLACK://open"
    ])
    func appSchemesLeave(address: String) {
        #expect(ExternalURLRouting.leavesBrowser(URL(string: address)))
    }

    @Test("Addresses WebKit loads stay in the tab", arguments: [
        "https://claude.ai", "http://localhost:3000", "about:blank", "blob:https://a.com/1",
        "data:text/plain,hi", "file:///tmp/a.html", "javascript:void(0)", "redent-devtools://frontend/x"
    ])
    func webSchemesStay(address: String) {
        #expect(!ExternalURLRouting.leavesBrowser(URL(string: address)))
    }

    @Test("A missing or schemeless address stays in the tab")
    func missingAddressStays() {
        #expect(!ExternalURLRouting.leavesBrowser(nil))
        #expect(!ExternalURLRouting.leavesBrowser(URL(string: "relative/path")))
    }
}
