import Foundation
import Security
import Testing
import RedentKit
@testable import RedentVault

struct KeychainItemDeleteFallbackTests {
    @Test func missingDataProtectionEntitlementFallsBackToLegacyItem() throws {
        let access = KeychainItemAccess(service: "test", dataProtection: true)
        var dataProtectionQueries: [Bool] = []

        try access.delete(account: "account") { query in
            dataProtectionQueries.append(query[kSecUseDataProtectionKeychain as String] != nil)
            return dataProtectionQueries.count == 1 ? errSecMissingEntitlement : errSecSuccess
        }

        #expect(dataProtectionQueries == [true, false])
    }

    @Test func authenticationFailureDoesNotDeleteLegacyItem() {
        let access = KeychainItemAccess(service: "test", dataProtection: true)
        var attempts = 0

        #expect(throws: VaultError.authenticationFailed) {
            try access.delete(account: "account") { _ in
                attempts += 1
                return errSecAuthFailed
            }
        }

        #expect(attempts == 1)
    }

    @Test func legacyDeleteFailurePropagates() {
        let access = KeychainItemAccess(service: "test", dataProtection: true)
        var attempts = 0

        #expect(throws: VaultError.keychain(status: Int32(errSecNotAvailable))) {
            try access.delete(account: "account") { query in
                attempts += 1
                return query[kSecUseDataProtectionKeychain as String] == nil
                    ? errSecNotAvailable : errSecItemNotFound
            }
        }

        #expect(attempts == 2)
    }
}
