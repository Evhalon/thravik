import Foundation
import Observation
import RedentKit

/// The user's site permissions, held in memory so the engine can be answered
/// the moment a page asks — a capture prompt cannot wait on disk.
///
/// Writes go through to the store; reads never do. A site with no stored
/// decision answers `.ask`, so a cold or failed load prompts rather than grants.
@MainActor @Observable
public final class SitePermissionLedger {
    private var policies: [SiteKey: SitePolicy] = [:]
    private let store: any SitePolicyStoring

    public init(store: any SitePolicyStoring) { self.store = store }

    public func load() async {
        let stored = await store.all()
        policies = Dictionary(stored.map { ($0.key, $0) }, uniquingKeysWith: { _, latest in latest })
    }

    public func decision(_ key: SiteKey, _ permission: SitePermission) -> PermissionDecision {
        policies[key]?.decision(for: permission) ?? .ask
    }

    public func policy(for key: SiteKey) -> SitePolicy {
        policies[key] ?? SitePolicy(key: key)
    }

    public func allowsInvalidCertificate(at key: SiteKey) -> Bool {
        policy(for: key).allowsInvalidCertificate
    }

    public func allowInvalidCertificate(at key: SiteKey) {
        var policy = policy(for: key)
        policy.allowsInvalidCertificate = true
        policies[key] = policy
        Task { [store] in await store.save(policy) }
    }

    public func set(_ decision: PermissionDecision, for permission: SitePermission, at key: SiteKey) {
        var policy = policy(for: key)
        policy.permissions[permission] = decision
        policies[key] = policy
        Task { [store] in await store.save(policy) }
    }
}
