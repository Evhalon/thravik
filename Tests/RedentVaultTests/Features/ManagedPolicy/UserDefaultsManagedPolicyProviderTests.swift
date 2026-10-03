import Foundation
import Testing
@testable import RedentVault
@testable import RedentKit

@Suite("UserDefaults managed policy provider")
struct UserDefaultsManagedPolicyProviderTests {
    @Test("Ignores keys that are not forced")
    func ignoresNonForced() {
        let suite = "managed-policy-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.set(true, forKey: ManagedPolicyUserDefaultsKeys.disablePrivateWindows)
        let provider = UserDefaultsManagedPolicyProvider(defaults: defaults, isForced: { _ in false })
        #expect(provider.current().disablePrivateWindows == nil)
        defaults.removePersistentDomain(forName: suite)
    }

    @Test("Plain user defaults writes cannot spoof policy with the default forced check")
    func defaultCheckerIgnoresUserWrites() throws {
        let suite = "managed-policy-tests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.set(true, forKey: ManagedPolicyUserDefaultsKeys.disablePrivateWindows)
        defaults.set(["evil.com"], forKey: ManagedPolicyUserDefaultsKeys.urlBlocklist)
        defaults.set("https://spoof.test", forKey: ManagedPolicyUserDefaultsKeys.homepageURL)
        #expect(!UserDefaultsManagedPolicyProvider(defaults: defaults).current().isActive)
        defaults.removePersistentDomain(forName: suite)
    }

    @Test("Reads forced keys only")
    func readsForced() {
        let suite = "managed-policy-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.set(true, forKey: ManagedPolicyUserDefaultsKeys.disablePrivateWindows)
        defaults.set(["evil.com"], forKey: ManagedPolicyUserDefaultsKeys.urlBlocklist)
        let forced: Set<String> = [
            ManagedPolicyUserDefaultsKeys.disablePrivateWindows,
            ManagedPolicyUserDefaultsKeys.urlBlocklist
        ]
        let provider = UserDefaultsManagedPolicyProvider(defaults: defaults) { forced.contains($0) }
        let policy = provider.current()
        #expect(policy.disablePrivateWindows == true)
        #expect(policy.blockedURLPatterns == ["evil.com"])
        defaults.removePersistentDomain(forName: suite)
    }
}
