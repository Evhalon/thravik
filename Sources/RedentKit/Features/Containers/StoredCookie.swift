import Foundation

/// A session cookie carried across a relaunch.
///
/// WebKit forgets cookies without an expiry the moment its process exits, so
/// a sign-in that set only a session cookie was lost on every quit — where
/// Safari and Chrome, restoring the previous session, keep the user signed in.
public struct StoredCookie: Codable, Hashable, Sendable {
    public var name: String
    public var value: String
    public var domain: String
    public var path: String
    public var isSecure: Bool
    public var isHTTPOnly: Bool
    public var sameSite: String?

    public init(
        name: String, value: String, domain: String, path: String,
        flags: (isSecure: Bool, isHTTPOnly: Bool), sameSite: String? = nil
    ) {
        self.name = name
        self.value = value
        self.domain = domain
        self.path = path
        self.isSecure = flags.isSecure
        self.isHTTPOnly = flags.isHTTPOnly
        self.sameSite = sameSite
    }

    /// Only cookies WebKit would drop are kept: a cookie with an expiry is
    /// already on disk, and duplicating it would outlive a server's revocation.
    public init?(_ cookie: HTTPCookie) {
        guard cookie.isSessionOnly else { return nil }
        self.init(
            name: cookie.name, value: cookie.value, domain: cookie.domain, path: cookie.path,
            flags: (cookie.isSecure, cookie.isHTTPOnly), sameSite: cookie.sameSitePolicy?.rawValue
        )
    }

    public var httpCookie: HTTPCookie? {
        var properties: [HTTPCookiePropertyKey: Any] = [
            .name: name, .value: value, .domain: domain, .path: path,
        ]
        if isSecure { properties[.secure] = "TRUE" }
        if isHTTPOnly { properties[HTTPCookiePropertyKey("HttpOnly")] = "TRUE" }
        if let sameSite { properties[.sameSitePolicy] = sameSite }
        return HTTPCookie(properties: properties)
    }
}
