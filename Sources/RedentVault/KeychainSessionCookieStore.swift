import Foundation
import RedentKit

/// One Keychain item per Container holds its session cookies as JSON.
public struct KeychainSessionCookieStore: SessionCookieStoring {
    private let keychain: KeychainStore

    public init(service: String = "app.redent.session-cookies") {
        keychain = KeychainStore(service: service)
    }

    public func load(container: UUID) async -> [StoredCookie] {
        guard let item = try? await keychain.fetch(account: container.uuidString),
              let cookies = try? JSONDecoder().decode([StoredCookie].self, from: item.valueData)
        else { return [] }
        return cookies
    }

    public func save(_ cookies: [StoredCookie], container: UUID) async {
        guard !cookies.isEmpty else { return await remove(container: container) }
        guard let data = try? JSONEncoder().encode(cookies) else { return }
        try? await keychain.upsert(
            account: container.uuidString, label: "Redent session cookies", valueData: data
        )
    }

    public func remove(container: UUID) async {
        try? await keychain.delete(account: container.uuidString)
    }
}
