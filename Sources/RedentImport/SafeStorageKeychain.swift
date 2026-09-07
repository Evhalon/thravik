import Foundation
import RedentKit
import Security

/// Reads a Chromium family's password-encryption secret from the Keychain.
/// Read-only: Redent never writes to another browser's Keychain item.
enum SafeStorageKeychain {
    private static let serviceSuffix = " Safe Storage"

    /// The Keychain account Chromium stores its safe-storage secret under is
    /// the family name on its own — e.g. service "Comet Safe Storage" pairs
    /// with account "Comet".
    private static func account(forService service: String) -> String {
        guard service.hasSuffix(serviceSuffix) else { return service }
        return String(service.dropLast(serviceSuffix.count))
    }

    /// Returns the raw secret bytes, or throws `.decryptionKeyUnavailable`
    /// if the item is missing or the user denies Keychain access.
    static func secret(service: String) throws -> Data {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account(forService: service),
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        query.removeAll()

        guard status == errSecSuccess, let data = result as? Data else {
            throw ImportError.decryptionKeyUnavailable
        }
        return data
    }
}
