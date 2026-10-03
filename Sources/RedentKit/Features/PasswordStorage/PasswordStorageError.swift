import Foundation

public enum PasswordStorageError: Error, Sendable, Equatable {
    case unavailable
    case providerChanged
    case locked
    case conflictingCredentials
    case invalidSyncPassword
    case weakSyncPassword
    case invalidRecoveryCode
}
