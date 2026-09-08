import Foundation
import RedentKit

/// Stores all logins in one Keychain item. Ad-hoc development signatures can
/// therefore cause at most one ACL prompt after a rebuild, never one per login.
public actor KeychainCredentialStore: CredentialStoring {
    private static let vaultAccount = "redent-credential-vault-v1"
    private let vault: KeychainStore
    private let legacy: KeychainStore

    public init(service: String = "app.redent.browser.credentials") {
        vault = KeychainStore(service: "\(service).vault")
        legacy = KeychainStore(service: service)
    }

    public func credentials(for origin: Origin, in spaceID: UUID?) async throws -> [Credential] {
        try await allCredentials().filter {
            $0.origin.matches(origin) && (spaceID == nil || $0.spaceID == spaceID)
        }
    }

    public func allCredentials() async throws -> [Credential] {
        sort(try await currentCredentials())
    }

    public func save(_ credential: Credential) async throws {
        var credentials = try await currentCredentials()
        credentials.removeAll { $0.id == credential.id }
        credentials.append(credential)
        try await write(credentials)
    }

    @discardableResult
    public func importCredentials(_ credentials: [Credential]) async throws -> [Credential] {
        let existing = try await currentCredentials()
        let fresh = CredentialImportDeduper.newcomers(in: credentials, alreadyHave: existing)
        guard !fresh.isEmpty else { return [] }
        try await write(existing + fresh)
        return fresh
    }

    public func markUsed(_ id: UUID) async throws {
        var credentials = try await currentCredentials()
        guard let index = credentials.firstIndex(where: { $0.id == id }) else {
            throw VaultError.itemNotFound
        }
        credentials[index].useCount += 1
        credentials[index].lastUsedAt = .now
        try await write(credentials)
    }

    public func delete(_ id: UUID) async throws {
        var credentials = try await currentCredentials()
        credentials.removeAll { $0.id == id }
        try await write(credentials)
    }

    private func currentCredentials() async throws -> [Credential] {
        do {
            let item = try await vault.loadOrUnlock(
                account: Self.vaultAccount,
                label: "Thravik Password Vault"
            )
            return try CredentialVaultCodec.decode(item.valueData)
        } catch VaultError.itemNotFound {
            return try await migrateLegacy()
        }
    }

    private func write(_ credentials: [Credential]) async throws {
        try await vault.upsert(
            account: Self.vaultAccount,
            label: "Thravik Password Vault",
            valueData: try CredentialVaultCodec.encode(Self.dedupe(credentials))
        )
    }

    private func sort(_ credentials: [Credential]) -> [Credential] {
        credentials.sorted {
            if $0.useCount != $1.useCount { return $0.useCount > $1.useCount }
            return ($0.lastUsedAt ?? .distantPast) > ($1.lastUsedAt ?? .distantPast)
        }
    }

    private static func dedupe(_ credentials: [Credential]) -> [Credential] {
        var best: [String: Credential] = [:]
        for credential in credentials {
            let space = credential.spaceID?.uuidString ?? "-"
            let key = "\(space)|\(credential.origin.scheme)|\(credential.origin.host)|\(credential.username)"
            if let old = best[key], old.createdAt >= credential.createdAt { continue }
            best[key] = credential
        }
        return Array(best.values)
    }

    private func migrateLegacy() async throws -> [Credential] {
        let leftover = await loadLegacy()
        guard !leftover.isEmpty else { return [] }
        try await write(leftover)
        for credential in leftover {
            try? await legacy.delete(account: credential.id.uuidString)
        }
        return leftover
    }

    private func loadLegacy() async -> [Credential] {
        let silent = await legacy.fetchAll().compactMap(KeychainCredentialCodec.decode)
        if !silent.isEmpty { return silent }
        return await legacy.fetchAll(allowingInteraction: true)
            .compactMap(KeychainCredentialCodec.decode)
    }
}
