import Foundation
import RedentKit

/// Holds every Container's session cookies in one Keychain item, so a new
/// signing identity costs one "Always Allow" for all Spaces, not one per Space.
public actor KeychainSessionCookieStore: SessionCookieStoring {
    private static let vaultAccount = "redent-session-cookie-vault-v1"
    private static let label = "Thravik session cookies"
    private let vault: KeychainStore
    private let legacy: KeychainStore
    /// Shared by concurrent first reads, so Spaces restoring at launch wait on
    /// one unlock instead of each raising its own.
    private var loading: Task<[UUID: [StoredCookie]]?, Never>?

    public init(service: String = "app.redent.session-cookies") {
        vault = KeychainStore(service: "\(service).vault")
        legacy = KeychainStore(service: service)
    }

    public func load(container: UUID) async -> [StoredCookie] {
        await contents()?[container] ?? []
    }

    public func save(_ cookies: [StoredCookie], container: UUID) async {
        await edit { $0[container] = cookies.isEmpty ? nil : cookies }
    }

    public func remove(container: UUID) async {
        await edit { $0[container] = nil }
    }

    /// A vault that could not be read is never written: saving one Space's
    /// cookies over it would erase every other Space's.
    private func edit(_ change: (inout [UUID: [StoredCookie]]) -> Void) async {
        guard var cookies = await contents() else { return }
        let before = cookies
        change(&cookies)
        guard cookies != before else { return }
        loading = Task { cookies }
        try? await write(cookies)
    }

    private func contents() async -> [UUID: [StoredCookie]]? {
        if let loading { return await loading.value }
        let task = Task { await self.read() }
        loading = task
        return await task.value
    }

    private func read() async -> [UUID: [StoredCookie]]? {
        do {
            let item = try await vault.loadOrUnlock(account: Self.vaultAccount, label: Self.label)
            return try SessionCookieVaultCodec.decode(item.valueData)
        } catch VaultError.itemNotFound {
            return await migrateLegacy()
        } catch {
            return nil
        }
    }

    /// Only items readable without a dialog move over. Asking per leftover
    /// item is the prompt storm this store exists to end; a Space whose old
    /// item stays locked signs in again once instead.
    private func migrateLegacy() async -> [UUID: [StoredCookie]] {
        let items = await legacy.fetchAll()
        let cookies = SessionCookieVaultCodec.decodeLegacy(items)
        guard !cookies.isEmpty else { return [:] }
        guard (try? await write(cookies)) != nil else { return cookies }
        for item in items {
            try? await legacy.delete(account: item.account)
        }
        return cookies
    }

    private func write(_ cookies: [UUID: [StoredCookie]]) async throws {
        try await vault.upsert(
            account: Self.vaultAccount,
            label: Self.label,
            valueData: try SessionCookieVaultCodec.encode(cookies)
        )
    }
}
