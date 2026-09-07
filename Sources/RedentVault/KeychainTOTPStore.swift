import Foundation
import RedentKit

/// All TOTP accounts in one Keychain item. Same reason as the password vault:
/// ad-hoc rebuilds must not prompt once per seed, and a silent miss on N items
/// used to look like the authenticator had been wiped.
public struct KeychainTOTPStore: TOTPAccountStoring {
    private static let vaultAccount = "redent-totp-vault-v1"
    private let vault: KeychainStore
    private let legacy: KeychainStore

    public init(service: String = "app.redent.browser.totp") {
        vault = KeychainStore(service: "\(service).vault")
        legacy = KeychainStore(service: service)
    }

    public func allAccounts() async throws -> [TOTPAccount] {
        try await currentAccounts()
    }

    public func accounts(for origin: Origin) async throws -> [TOTPAccount] {
        TOTPAccountMatcher.rank(try await allAccounts(), for: origin)
    }

    public func save(_ account: TOTPAccount) async throws {
        var accounts = try await currentAccounts()
        accounts.removeAll { $0.id == account.id }
        accounts.append(account)
        try await write(accounts)
    }

    public func importAccounts(_ accounts: [TOTPAccount]) async throws -> [TOTPAccount] {
        var existing = try await currentAccounts()
        var knownSecrets = Set(existing.map(\.secret))
        var added: [TOTPAccount] = []
        for account in accounts where !knownSecrets.contains(account.secret) {
            existing.append(account)
            knownSecrets.insert(account.secret)
            added.append(account)
        }
        guard !added.isEmpty else { return [] }
        try await write(existing)
        return added
    }

    public func link(_ id: UUID, to domain: String) async throws {
        var accounts = try await currentAccounts()
        guard let index = accounts.firstIndex(where: { $0.id == id }) else {
            throw VaultError.itemNotFound
        }
        accounts[index].linkedDomains.insert(TOTPAccountMatcher.normalizeDomain(domain))
        try await write(accounts)
    }

    public func delete(_ id: UUID) async throws {
        var accounts = try await currentAccounts()
        accounts.removeAll { $0.id == id }
        try await write(accounts)
    }

    private func currentAccounts() async throws -> [TOTPAccount] {
        do {
            let item = try await vault.loadOrUnlock(
                account: Self.vaultAccount,
                label: "Redent Authenticator Vault"
            )
            return try TOTPVaultCodec.decode(item.valueData)
        } catch VaultError.itemNotFound {
            return try await migrateLegacy()
        }
    }

    private func write(_ accounts: [TOTPAccount]) async throws {
        try await vault.upsert(
            account: Self.vaultAccount,
            label: "Redent Authenticator Vault",
            valueData: try TOTPVaultCodec.encode(accounts)
        )
    }

    private func migrateLegacy() async throws -> [TOTPAccount] {
        let leftover = await loadLegacy()
        guard !leftover.isEmpty else { return [] }
        try await write(leftover)
        for account in leftover {
            try? await legacy.delete(account: account.id.uuidString)
        }
        return leftover
    }

    private func loadLegacy() async -> [TOTPAccount] {
        let silent = await legacy.fetchAll().compactMap(KeychainTOTPCodec.decode)
        if !silent.isEmpty { return silent }
        return await legacy.fetchAll(allowingInteraction: true).compactMap(KeychainTOTPCodec.decode)
    }
}
