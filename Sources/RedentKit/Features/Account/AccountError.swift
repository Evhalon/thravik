import Foundation

public enum AccountError: Error, Sendable, Equatable {
    case invalidConfiguration
    case invalidEmail
    case invalidCode
    case invalidPassword
    case invalidCredentials
    case unsupportedOperation
    case invalidResponse
    case unauthorized
    case rateLimited
    case unavailable
}
