import Foundation

public protocol PasswordVaultAccessing: Sendable {
    func status() async throws -> PasswordVaultState
    func passwordConfigured() async throws -> Bool
    func prepareVault(password: String) async throws -> String
    func unlock(password: String) async throws -> String
    func enablePassword(password: String, recoveryCode: String) async throws
    func prepareVault() async throws -> String
    func activateVault() async throws
    func recover(code: String) async throws
}

public extension PasswordVaultAccessing {
    func passwordConfigured() async throws -> Bool { false }
    func prepareVault(password: String) async throws -> String { throw PasswordStorageError.unavailable }
    func unlock(password: String) async throws -> String { throw PasswordStorageError.unavailable }
    func enablePassword(password: String, recoveryCode: String) async throws { throw PasswordStorageError.unavailable }
}
