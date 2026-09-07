import Foundation
import Security
import Testing
@testable import RedentVault

@Suite("Keychain query shape")
struct KeychainQueryTests {
    @Test("Data-protection writes set the flag")
    func dataProtectionFlag() {
        let query = KeychainQuery.base(service: "app.redent.browser.credentials", dataProtection: true)
        #expect(query[kSecUseDataProtectionKeychain as String] as? Bool == true)
        #expect(query[kSecAttrSynchronizable as String] as? Bool == false)
    }

    @Test("File-based reads omit the flag so legacy items still match")
    func fileBasedOmitsFlag() {
        let query = KeychainQuery.base(service: "app.redent.browser.credentials", dataProtection: false)
        #expect(query[kSecUseDataProtectionKeychain as String] == nil)
    }

    @Test("Silent queries ask the Keychain to fail instead of prompting")
    func silenceFailsClosed() {
        var query = KeychainQuery.base(service: "app.redent.browser.credentials", dataProtection: false)
        KeychainQuery.silence(&query)
        #expect(query["u_AuthUI"] as? String == "fail")
        #expect(query[kSecUseAuthenticationContext as String] != nil)
    }
}
