import Testing
@testable import Redent

struct KeychainNamespaceTests {
    @Test func debugBuildsKeepTheirOwnVaults() {
        #if DEBUG
        #expect(KeychainNamespace.service("app.redent.browser.totp") == "app.redent.browser.totp.debug")
        #else
        #expect(KeychainNamespace.service("app.redent.browser.totp") == "app.redent.browser.totp")
        #endif
    }
}
