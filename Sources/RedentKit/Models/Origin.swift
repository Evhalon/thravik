import Foundation

/// A security origin reduced to its registrable domain (eTLD+1).
///
/// Credentials and TOTP accounts are matched on this, never on a substring of
/// the URL — `evil-google.com` must not match `google.com`.
public struct Origin: Hashable, Sendable, Codable, CustomStringConvertible {
    public let scheme: String
    public let host: String

    public init(scheme: String, host: String) {
        self.scheme = scheme.lowercased()
        self.host = host.lowercased()
    }

    public init?(url: URL) {
        guard let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              let host = url.host()?.lowercased(), !host.isEmpty
        else { return nil }
        self.init(scheme: scheme, host: host)
    }

    /// The registrable domain: `mail.google.com` → `google.com`,
    /// `foo.co.uk` → `foo.co.uk`.
    public var registrableDomain: String {
        PublicSuffix.registrableDomain(of: host) ?? host
    }

    /// Two origins are autofill-compatible when they share a registrable domain.
    public func matches(_ other: Origin) -> Bool {
        registrableDomain == other.registrableDomain
    }

    /// Host without a leading `www.`, for display.
    public var displayHost: String {
        host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    }

    public var description: String { "\(scheme)://\(host)" }
}
