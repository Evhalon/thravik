import Foundation

public enum TOTPAlgorithm: String, Codable, Sendable, CaseIterable {
    case sha1, sha256, sha512
}

/// A one-time-password account, typically imported from a Google Authenticator
/// export QR. `secret` is raw bytes — never Base32 text, never a `String`.
public struct TOTPAccount: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let issuer: String
    public let accountName: String
    public let secret: Data
    public let algorithm: TOTPAlgorithm
    public let digits: Int
    public let period: Int
    /// Domains the user has pinned to this account, on top of issuer matching.
    public var linkedDomains: Set<String>

    public init(
        id: UUID = UUID(),
        issuer: String,
        accountName: String,
        secret: Data,
        algorithm: TOTPAlgorithm = .sha1,
        digits: Int = 6,
        period: Int = 30,
        linkedDomains: Set<String> = []
    ) {
        self.id = id
        self.issuer = issuer
        self.accountName = accountName
        self.secret = secret
        self.algorithm = algorithm
        self.digits = max(6, min(digits, 10))
        self.period = period > 0 ? period : 30
        self.linkedDomains = linkedDomains
    }

    public var displayName: String {
        issuer.isEmpty ? accountName : "\(issuer) · \(accountName)"
    }

    /// Safe to log: identifies the account without revealing the seed.
    public var redactedDescription: String {
        "TOTPAccount(\(issuer)/\(accountName), \(digits)d/\(period)s)"
    }
}

/// A generated code plus the window it belongs to.
public struct TOTPCode: Hashable, Sendable {
    public let digits: String
    public let validFrom: Date
    public let period: Int

    public init(digits: String, validFrom: Date, period: Int) {
        self.digits = digits
        self.validFrom = validFrom
        self.period = period
    }

    public var expiresAt: Date { validFrom.addingTimeInterval(TimeInterval(period)) }

    public func secondsRemaining(at now: Date = .now) -> Int {
        max(0, Int(expiresAt.timeIntervalSince(now).rounded(.up)))
    }

    /// 1.0 at the start of the window, 0.0 at expiry — drives the ring.
    public func fractionRemaining(at now: Date = .now) -> Double {
        let left = expiresAt.timeIntervalSince(now)
        return min(1, max(0, left / Double(period)))
    }

    /// `123456` → `123 456`, easier to read off and retype.
    public var grouped: String {
        let mid = digits.count / 2
        let idx = digits.index(digits.startIndex, offsetBy: mid)
        return "\(digits[..<idx]) \(digits[idx...])"
    }
}
