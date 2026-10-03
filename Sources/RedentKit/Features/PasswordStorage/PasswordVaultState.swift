import Foundation

public enum PasswordVaultState: Sendable, Equatable {
    case ready
    case needsCreation
    case needsRecovery
}
