import Foundation
import Observation
import RedentKit

/// Drives the per-site privacy screen: what this site has stored, what it is
/// allowed to do, and what a Forget pass actually removed.
@MainActor @Observable
public final class SitePrivacyModel {
    public private(set) var records: [SiteDataRecord] = []
    public private(set) var report: ForgetSiteReport?
    public private(set) var isWorking = false
    public private(set) var policy: SitePolicy

    public let origin: Origin
    private let context: BrowsingContext
    private let permissions: SitePermissionLedger
    private let siteData: any SiteDataManaging
    private let forgetting: ForgetSiteService

    public struct Configuration {
        public var origin: Origin
        public var context: BrowsingContext
        public var permissions: SitePermissionLedger
        public var siteData: any SiteDataManaging
        public var forgetting: ForgetSiteService

        public init(origin: Origin, context: BrowsingContext, permissions: SitePermissionLedger,
                    siteData: any SiteDataManaging, forgetting: ForgetSiteService) {
            self.origin = origin
            self.context = context
            self.permissions = permissions
            self.siteData = siteData
            self.forgetting = forgetting
        }
    }

    public init(configuration: Configuration) {
        origin = configuration.origin
        context = configuration.context
        permissions = configuration.permissions
        siteData = configuration.siteData
        forgetting = configuration.forgetting
        policy = SitePolicy(key: SiteKey(
            origin: configuration.origin,
            containerID: configuration.context.containerID ?? BrowserContainer.defaultID
        ))
    }

    /// The engine attributes records to a registrable domain, so this is what
    /// the site shares a data scope with — not necessarily this exact host.
    public var deletionScope: String { origin.registrableDomain }

    public func load() async {
        isWorking = true
        defer { isWorking = false }
        policy = permissions.policy(for: policy.key)
        let all = await siteData.records(in: context)
        records = all.filter { $0.displayName.caseInsensitiveCompare(deletionScope) == .orderedSame }
    }

    public func set(_ decision: PermissionDecision, for permission: SitePermission) {
        permissions.set(decision, for: permission, at: policy.key)
        policy = permissions.policy(for: policy.key)
    }

    public func forgetSite() async {
        isWorking = true
        defer { isWorking = false }
        report = await forgetting.forget(origin)
        records = await siteData.records(in: context)
            .filter { $0.displayName.caseInsensitiveCompare(deletionScope) == .orderedSame }
    }
}
