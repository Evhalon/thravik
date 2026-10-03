import Foundation

public struct AccountIdentity: Sendable, Codable, Equatable {
    public let email: String?
    public let loginMethod: AccountLoginMethod

    public init(email: String?, loginMethod: AccountLoginMethod) {
        self.email = email
        self.loginMethod = loginMethod
    }
}
