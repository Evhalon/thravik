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
    /// The user explicitly chose to continue despite this origin's bad TLS
    /// certificate. This never extends to a sibling host.
    public var allowsInvalidCertificate: Bool

    public var id: SiteKey { key }

    public init(
        key: SiteKey,
        permissions: [SitePermission: PermissionDecision] = [:],
        blocksTrackers: Bool? = nil,
        allowsInvalidCertificate: Bool = false
    ) {
        self.key = key
        self.permissions = permissions
        self.blocksTrackers = blocksTrackers
        self.allowsInvalidCertificate = allowsInvalidCertificate
    }

    public func decision(for permission: SitePermission) -> PermissionDecision {
        permissions[permission] ?? .ask
    }

    /// Nothing decided and nothing overridden: not worth storing.
    public var isEmpty: Bool {
        blocksTrackers == nil && !allowsInvalidCertificate && permissions.values.allSatisfy { $0 == .ask }
    }

    private enum CodingKeys: String, CodingKey {
        case key, permissions, blocksTrackers, allowsInvalidCertificate
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        key = try container.decode(SiteKey.self, forKey: .key)
        permissions = try container.decodeIfPresent([SitePermission: PermissionDecision].self, forKey: .permissions) ?? [:]
        blocksTrackers = try container.decodeIfPresent(Bool.self, forKey: .blocksTrackers)
        allowsInvalidCertificate = try container.decodeIfPresent(Bool.self, forKey: .allowsInvalidCertificate) ?? false
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(key, forKey: .key)
        try container.encode(permissions, forKey: .permissions)
        try container.encodeIfPresent(blocksTrackers, forKey: .blocksTrackers)
        try container.encode(allowsInvalidCertificate, forKey: .allowsInvalidCertificate)
    }
}
