import Foundation

public enum AccountLoginMethod: String, Codable, Sendable, Equatable {
    case email
    case google
    case unknown
}
