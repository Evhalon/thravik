import Foundation
import RedentKit

public actor KeychainSyncKeyStore: SyncKeyStoring {
    private let store: KeychainStore

    public init(service: String) { store = KeychainStore(service: service) }

    public func load(accountID: UUID) async throws -> Data? {
        do {
            let item = try await store.fetch(account: accountID.uuidString)
            guard item.valueData.count == 32 else { throw VaultError.invalidData }
            return item.valueData
        } catch VaultError.itemNotFound { return nil }
    }

    public func save(_ key: Data, accountID: UUID) async throws {
        guard key.count == 32 else { throw VaultError.invalidData }
        try await store.upsert(account: accountID.uuidString, label: "Redent sync key", valueData: key)
    }

    public func delete(accountID: UUID) async throws { try await store.delete(account: accountID.uuidString) }
}
