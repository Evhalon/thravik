import Foundation
import RedentKit

/// Applies MDM policy on load and preserves locked fields on save.
///
/// `policy` must report the policy the caller's effective settings were
/// derived from: merged against a fresher read, a policy removed before the
/// windows refresh would write its managed values into the user's settings.
public struct PolicyAwareSettingsStore: SettingsStoring {
    private let inner: any SettingsStoring
    private let policy: any ManagedPolicyProviding

    public init(inner: any SettingsStoring, policy: any ManagedPolicyProviding) {
        self.inner = inner
        self.policy = policy
    }

    public func load() -> BrowserSettings {
        ManagedPolicyApplication.apply(user: inner.load(), policy: policy.current()).settings
    }

    public func save(_ settings: BrowserSettings) {
        let current = policy.current()
        guard current.isActive else { return inner.save(settings) }
        inner.save(ManagedPolicyApplication.storedUserSettings(
            effective: settings,
            previousStored: inner.load(),
            policy: current
        ))
    }
}
