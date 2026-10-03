import Foundation

public struct AccountSession: Sendable, Codable, Equatable, CustomStringConvertible {
    public let accountID: UUID
    public let accessToken: String
    public let refreshToken: String
    public let expiresAt: Date
    public let identity: AccountIdentity

    public init(accountID: UUID, accessToken: String, refreshToken: String, expiresAt: Date) {
        self.init(accountID: accountID, accessToken: accessToken, refreshToken: refreshToken,
                  expiresAt: expiresAt, identity: AccountIdentity(email: nil, loginMethod: .unknown))
    }

    public init(accountID: UUID, accessToken: String, refreshToken: String, expiresAt: Date,
                identity: AccountIdentity) {
        self.accountID = accountID
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
        self.identity = identity
    }

    public var description: String { "AccountSession(redacted)" }
    public var email: String? { identity.email }
    public var loginMethod: AccountLoginMethod { identity.loginMethod }

    private enum CodingKeys: String, CodingKey {
        case accountID, accessToken, refreshToken, expiresAt, identity, email, loginMethod
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        accountID = try values.decode(UUID.self, forKey: .accountID)
        accessToken = try values.decode(String.self, forKey: .accessToken)
        refreshToken = try values.decode(String.self, forKey: .refreshToken)
        expiresAt = try values.decode(Date.self, forKey: .expiresAt)
        if let storedIdentity = try values.decodeIfPresent(AccountIdentity.self, forKey: .identity) {
            identity = storedIdentity
        } else {
            let email = try values.decodeIfPresent(String.self, forKey: .email)
            let method = try values.decodeIfPresent(AccountLoginMethod.self, forKey: .loginMethod) ?? .unknown
            identity = AccountIdentity(email: email, loginMethod: method)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(accountID, forKey: .accountID)
        try values.encode(accessToken, forKey: .accessToken)
        try values.encode(refreshToken, forKey: .refreshToken)
        try values.encode(expiresAt, forKey: .expiresAt)
        try values.encode(identity, forKey: .identity)
    }
}
