import Foundation

/// Website data as the engine sees it. The domain layer names scopes; only the
/// engine knows they are WebKit stores and records.
@MainActor
public protocol SiteDataManaging: AnyObject {
    /// Every context currently backed by a live store.
    var loadedContexts: [BrowsingContext] { get }
    func records(in context: BrowsingContext) async -> [SiteDataRecord]
    /// Removes exactly the records the engine attributes to `domain`.
    /// - Returns: the record names actually removed.
    @discardableResult
    func removeRecords(matching domain: String, in context: BrowsingContext) async -> [String]
}

/// The user's per-site decisions, kept between launches.
public protocol SitePolicyStoring: Sendable {
    func policy(for key: SiteKey) async -> SitePolicy
    func save(_ policy: SitePolicy) async
    func all() async -> [SitePolicy]
}
