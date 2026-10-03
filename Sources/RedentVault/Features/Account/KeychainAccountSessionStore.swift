import Foundation
import RedentKit

public actor KeychainAccountSessionStore: AccountSessionStoring {
    private let store: KeychainStore
    private let account = "account-session-v1"

    public init(service: String) { store = KeychainStore(service: service) }

    public func load() async throws -> AccountSession? {
        do {
            let item = try await store.fetch(account: account)
            guard let session = try? JSONDecoder().decode(AccountSession.self, from: item.valueData)
            else { throw VaultError.invalidData }
            return session
        } catch VaultError.itemNotFound { return nil }
    }

    public func save(_ session: AccountSession) async throws {
        let bytes = try JSONEncoder().encode(session)
        try await store.upsert(account: account, label: "Redent account session", valueData: bytes)
    }

    public func clear() async throws { try await store.delete(account: account) }
}
