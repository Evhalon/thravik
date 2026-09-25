import Foundation
import RedentKit

/// Every Container's session cookies in one Keychain payload, keyed by the
/// Container's UUID string.
enum SessionCookieVaultCodec {
    static func encode(_ vault: [UUID: [StoredCookie]]) throws -> Data {
        let keyed = Dictionary(uniqueKeysWithValues: vault.map { ($0.key.uuidString, $0.value) })
        return try JSONEncoder().encode(keyed)
    }

    static func decode(_ data: Data) throws -> [UUID: [StoredCookie]] {
        let keyed = try JSONDecoder().decode([String: [StoredCookie]].self, from: data)
        var vault: [UUID: [StoredCookie]] = [:]
        for (key, cookies) in keyed {
            guard let container = UUID(uuidString: key) else { continue }
            vault[container] = cookies
        }
        return vault
    }

    /// Before the shared vault, each Container had its own item: the account
    /// was the Container's UUID and the value its cookie array.
    static func decodeLegacy(_ items: [KeychainStore.Item]) -> [UUID: [StoredCookie]] {
        var vault: [UUID: [StoredCookie]] = [:]
        for item in items {
            guard let container = UUID(uuidString: item.account),
                  let cookies = try? JSONDecoder().decode([StoredCookie].self, from: item.valueData),
                  !cookies.isEmpty
            else { continue }
            vault[container] = cookies
        }
        return vault
    }
}
