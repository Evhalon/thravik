import Foundation

/// A saved website login. The password never crosses this boundary as a
/// `String` beyond what the autofill bridge strictly needs.
public struct Credential: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let origin: Origin
    public let username: String
    public let password: String
    /// The Space this login belongs to. Logins saved before Spaces became
    /// profiles decode as nil and are adopted by the Work Space.
    public var spaceID: UUID?
    public let createdAt: Date
    public var lastUsedAt: Date?
    /// Bumped whenever the user picks this entry, to rank the autofill list.
    public var useCount: Int

    public init(
        id: UUID = UUID(),
        origin: Origin,
        username: String,
        password: String,
        spaceID: UUID? = nil,
        createdAt: Date = .now,
        lastUsedAt: Date? = nil,
        useCount: Int = 0
    ) {
        self.id = id
        self.origin = origin
        self.username = username
        self.password = password
        self.spaceID = spaceID
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
        self.useCount = useCount
    }

    /// Never include the password — this type is safe to log.
    public var redactedDescription: String {
        "Credential(\(origin.displayHost), \(username), •••)"
    }
}

/// A login the page offered that we have not saved yet.
public struct CredentialCandidate: Hashable, Sendable {
    public let origin: Origin
    public let username: String
    public let password: String
    /// The page was changing a password rather than signing in. Such forms
    /// rarely carry a username field, so the identity has to be resolved
    /// against what the vault already holds for the origin.
    public let isPasswordChange: Bool

    public init(origin: Origin, username: String, password: String, isPasswordChange: Bool = false) {
        self.origin = origin
        self.username = username
        self.password = password
        self.isPasswordChange = isPasswordChange
    }

    public func named(_ username: String) -> CredentialCandidate {
        CredentialCandidate(
            origin: origin, username: username,
            password: password, isPasswordChange: isPasswordChange
        )
    }
}
