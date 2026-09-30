import Testing
@testable import Redent

struct KeychainNamespaceTests {
    @Test func releaseKeepsTheBareServiceNames() {
        #expect(KeychainNamespace.suffix(forBundleID: "app.redent.browser") == "")
    }

    @Test func devBuildKeepsItsOwnVaults() {
        #expect(KeychainNamespace.suffix(forBundleID: "app.redent.browser.dev") == ".dev")
    }

    @Test func unbundledExecutableKeepsTheDebugVaults() {
        #expect(KeychainNamespace.suffix(forBundleID: nil) == ".debug")
        #expect(KeychainNamespace.suffix(forBundleID: "") == ".debug")
    }

    @Test func foreignBundleNeverSharesTheReleaseVaults() {
        #expect(KeychainNamespace.suffix(forBundleID: "com.apple.xctest") == ".com.apple.xctest")
    }
}
