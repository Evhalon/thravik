import Foundation

public protocol PasswordVaultAccessing: Sendable {
    func status() async throws -> PasswordVaultState
    func prepareVault() async throws -> String
    func activateVault() async throws
    func recover(code: String) async throws
}
