import Foundation

/// Identifies a site's decisions inside one Container.
///
/// Keyed by the exact scheme and host rather than the registrable domain: a
/// permission granted to `app.example.com` must not extend to `example.com`.
/// Website-data deletion is a different, coarser scope — see `SiteDataRecord`.
public struct SiteKey: Codable, Sendable, Hashable {
    public let scheme: String
    public let host: String
    public let containerID: UUID

    public init(origin: Origin, containerID: UUID) {
        self.scheme = origin.scheme
        self.host = origin.host
        self.containerID = containerID
    }

    public var displayHost: String { host.hasPrefix("www.") ? String(host.dropFirst(4)) : host }
}

/// What the user has decided about one site.
public struct SitePolicy: Codable, Sendable, Hashable, Identifiable {
    public let key: SiteKey
    public var permissions: [SitePermission: PermissionDecision]
    /// `nil` means "follow the global tracker setting" — an unset override, not
    /// a decision to allow trackers.
    public var blocksTrackers: Bool?

    public var id: SiteKey { key }

    public init(
        key: SiteKey,
        permissions: [SitePermission: PermissionDecision] = [:],
        blocksTrackers: Bool? = nil
    ) {
        self.key = key
        self.permissions = permissions
        self.blocksTrackers = blocksTrackers
    }

    public func decision(for permission: SitePermission) -> PermissionDecision {
        permissions[permission] ?? .ask
    }

    /// Nothing decided and nothing overridden: not worth storing.
    public var isEmpty: Bool {
        blocksTrackers == nil && permissions.values.allSatisfy { $0 == .ask }
    }
}
