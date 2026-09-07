import Foundation
import Testing
@testable import RedentVault

@Suite("Code identity for Keychain policy")
struct KeychainCodeIdentityTests {
    @Test("swift test has no Team ID, so vault writes stay file-based")
    func unsignedHostSkipsDataProtection() {
        #expect(KeychainCodeIdentity.teamIdentifier == nil)
        #expect(!KeychainCodeIdentity.usesDataProtection)
    }
}
