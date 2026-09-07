import Foundation

public enum VaultError: Error, Sendable, Equatable {
    case itemNotFound
    case duplicateItem
    case invalidData
    case authenticationFailed
    /// Raw `OSStatus` from Security.framework, for anything unmapped.
    case keychain(status: Int32)
}

/// Storage for website logins. Implemented by the Keychain adapter in RedentVault.
public protocol CredentialStoring: Sendable {
    /// Every credential whose registrable domain matches `origin`,
    /// most-recently-used first.
    func credentials(for origin: Origin) async throws -> [Credential]
    func allCredentials() async throws -> [Credential]
    func save(_ credential: Credential) async throws
    /// Imports a set with one atomic vault write, skipping existing logins.
    @discardableResult
    func importCredentials(_ credentials: [Credential]) async throws -> [Credential]
    /// Records a use, so the autofill list ranks sensibly.
    func markUsed(_ id: UUID) async throws
    func delete(_ id: UUID) async throws
}

public extension CredentialStoring {
    @discardableResult
    func importCredentials(_ credentials: [Credential]) async throws -> [Credential] {
        let fresh = CredentialImportDeduper.newcomers(
            in: credentials,
            alreadyHave: try await allCredentials()
        )
        for credential in fresh { try await save(credential) }
        return fresh
    }
}

/// Storage for TOTP seeds.
public protocol TOTPAccountStoring: Sendable {
    func allAccounts() async throws -> [TOTPAccount]
    /// Accounts plausibly belonging to `origin`, best match first.
    func accounts(for origin: Origin) async throws -> [TOTPAccount]
    func save(_ account: TOTPAccount) async throws
    /// Imports many at once, skipping seeds already present.
    /// - Returns: the accounts actually added.
    @discardableResult
    func importAccounts(_ accounts: [TOTPAccount]) async throws -> [TOTPAccount]
    func link(_ id: UUID, to domain: String) async throws
    func delete(_ id: UUID) async throws
}
