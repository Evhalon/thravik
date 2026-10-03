import Foundation
import Testing
import RedentKit
@testable import RedentVault

@Suite("Policy-aware settings store")
struct PolicyAwareSettingsStoreTests {
    private struct FixedPolicy: ManagedPolicyProviding {
        let policy: ManagedPolicy
        func current() -> ManagedPolicy { policy }
    }

    private static let forcing = ManagedPolicy(
        homepageURL: "https://managed.test",
        defaultSearchEngine: .builtIn(.google),
        disablePasswordSaving: true,
        forceTrackerBlocking: true
    )

    private func withDefaults(_ body: (UserDefaultsSettingsStore) throws -> Void) throws {
        let suite = "policy-aware-settings-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        try body(UserDefaultsSettingsStore(defaults: defaults))
    }

    @Test("Removing the policy restores the user's own values after an unrelated save")
    func policyRemovalRestoresUserValues() throws {
        try withDefaults { inner in
            let user = BrowserSettings(
                blocksTrackers: false, offersPasswordSave: true,
                searchEngine: .duckduckgo, homepage: "https://duckduckgo.com"
            )
            inner.save(user)
            let managed = PolicyAwareSettingsStore(inner: inner, policy: FixedPolicy(policy: Self.forcing))
            var effective = managed.load()
            #expect(effective.homepage == "https://managed.test")
            #expect(effective.searchEngine == .google)
            effective.tabLayout = .top
            managed.save(effective)

            let unmanaged = PolicyAwareSettingsStore(inner: inner, policy: FixedPolicy(policy: ManagedPolicy()))
            let restored = unmanaged.load()
            #expect(restored.homepage == "https://duckduckgo.com")
            #expect(restored.searchEngine == .duckduckgo)
            #expect(restored.customSearchEngines.isEmpty)
            #expect(!restored.blocksTrackers)
            #expect(restored.offersPasswordSave)
            #expect(restored.tabLayout == .top)
        }
    }

    @Test("Managed search engine never drags the user's homepage along")
    func managedEngineKeepsUserHomepage() throws {
        try withDefaults { inner in
            inner.save(BrowserSettings(searchEngine: .duckduckgo, homepage: "https://duckduckgo.com"))
            let policy = FixedPolicy(policy: ManagedPolicy(defaultSearchEngine: .builtIn(.google)))
            let managed = PolicyAwareSettingsStore(inner: inner, policy: policy)
            managed.save(managed.load())
            #expect(inner.load().homepage == "https://duckduckgo.com")
            #expect(inner.load().searchEngine == .duckduckgo)
        }
    }

    @Test("Without a policy, load and save pass straight through")
    func identityWithoutPolicy() throws {
        try withDefaults { inner in
            var settings = BrowserSettings(tabLayout: .top, blocksTrackers: false, homepage: "https://a.test")
            settings.showsBookmarksBar = true
            settings.sensitiveSiteHistoryDomains = ["bank.test"]
            let store = PolicyAwareSettingsStore(inner: inner, policy: FixedPolicy(policy: ManagedPolicy()))
            store.save(settings)
            #expect(inner.load() == settings)
            #expect(store.load() == settings)
        }
    }
}
