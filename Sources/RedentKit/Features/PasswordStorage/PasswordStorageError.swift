import Foundation

public enum PasswordStorageError: Error, Sendable, Equatable {
    case unavailable
    case providerChanged
    case locked
    case conflictingCredentials
}
