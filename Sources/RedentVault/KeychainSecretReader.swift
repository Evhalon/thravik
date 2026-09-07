import Foundation
import Security
import RedentKit

/// Reads secrets. Silent by default so a mixed ACL cannot pop a dialog per
/// leftover login. Callers that are already in a one-time unlock path may
/// opt into interaction to recover items after a signing-identity change.
enum KeychainSecretReader {
    static func allReadable(service: String, allowingInteraction: Bool = false) -> [KeychainStore.Item] {
        let read = { collect(service: service, allowingInteraction: allowingInteraction) }
        return allowingInteraction ? read() : KeychainInteraction.withDialogsDisabled(read)
    }

    private static func collect(service: String, allowingInteraction: Bool) -> [KeychainStore.Item] {
        let protected = (try? bulkCopy(
            service: service, dataProtection: true, allowingInteraction: allowingInteraction
        )) ?? []
        if !protected.isEmpty { return protected }
        if allowingInteraction {
            return (try? bulkCopy(
                service: service, dataProtection: false, allowingInteraction: true
            )) ?? []
        }
        return copyEach(service: service, dataProtection: false)
    }

    private static func bulkCopy(
        service: String, dataProtection: Bool, allowingInteraction: Bool
    ) throws -> [KeychainStore.Item] {
        var query = KeychainQuery.base(service: service, dataProtection: dataProtection)
        query[kSecMatchLimit as String] = kSecMatchLimitAll
        query[kSecReturnData as String] = true
        query[kSecReturnAttributes as String] = true
        if !allowingInteraction { KeychainQuery.silence(&query) }
        return try items(from: copy(query))
    }

    private static func copyEach(service: String, dataProtection: Bool) -> [KeychainStore.Item] {
        accounts(service: service, dataProtection: dataProtection).compactMap { account in
            var query = KeychainQuery.base(service: service, account: account, dataProtection: dataProtection)
            query[kSecReturnData as String] = true
            query[kSecReturnAttributes as String] = true
            KeychainQuery.silence(&query)
            return try? item(from: copy(query))
        }
    }

    private static func accounts(service: String, dataProtection: Bool) -> [String] {
        var query = KeychainQuery.base(service: service, dataProtection: dataProtection)
        query[kSecMatchLimit as String] = kSecMatchLimitAll
        query[kSecReturnAttributes as String] = true
        KeychainQuery.silence(&query)
        guard let result = try? copy(query) else { return [] }
        let rows = (try? KeychainAttributeCodec.dictionaries(from: result)) ?? []
        return rows.compactMap(KeychainAttributeCodec.account(from:))
    }

    private static func copy(_ query: [String: Any]) throws -> CFTypeRef? {
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        try KeychainStatus.check(status)
        return result
    }

    private static func items(from result: CFTypeRef?) throws -> [KeychainStore.Item] {
        guard let result else { return [] }
        return try KeychainAttributeCodec.dictionaries(from: result).compactMap { try? item(from: $0) }
    }

    private static func item(from result: CFTypeRef?) throws -> KeychainStore.Item {
        guard let dict = result as? [String: Any] else { throw VaultError.invalidData }
        return try item(from: dict)
    }

    private static func item(from dict: [String: Any]) throws -> KeychainStore.Item {
        try KeychainStore.item(from: dict)
    }
}
