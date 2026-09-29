import Foundation
import Security
import RedentKit

/// Create / update / delete / fetch-one. Data-protection only when the
/// binary has a Team ID — ad-hoc partitions die on every `make app`.
/// Reads never present Keychain UI unless the caller asks.
struct KeychainItemAccess {
    let service: String
    private let dataProtection: Bool

    init(service: String) {
        self.service = service
        dataProtection = KeychainCodeIdentity.usesDataProtection
    }

    func fetch(account: String, allowingInteraction: Bool = false) throws -> KeychainStore.Item {
        if let item = try? copy(
            account: account,
            dataProtection: true,
            allowingInteraction: allowingInteraction
        ) { return item }
        return try copy(
            account: account,
            dataProtection: false,
            allowingInteraction: allowingInteraction
        )
    }

    func exists(account: String) -> Bool {
        hasAccount(account, dataProtection: true) || hasAccount(account, dataProtection: false)
    }

    func add(account: String, label: String, valueData: Data, genericData: Data?) throws {
        if dataProtection {
            do {
                try insert(
                    account: account, label: label, valueData: valueData,
                    genericData: genericData, dataProtection: true
                )
                return
            } catch {}
        }
        try insert(
            account: account, label: label, valueData: valueData,
            genericData: genericData, dataProtection: false
        )
    }

    func update(account: String, label: String?, valueData: Data?, genericData: Data?) throws {
        let dataProtection = hasAccount(account, dataProtection: true)
        let query = KeychainQuery.base(service: service, account: account, dataProtection: dataProtection)
        var attributes: [String: Any] = [:]
        if let label { attributes[kSecAttrLabel as String] = label }
        if let valueData { attributes[kSecValueData as String] = valueData }
        if let genericData { attributes[kSecAttrGeneric as String] = genericData }
        try KeychainStatus.check(SecItemUpdate(query as CFDictionary, attributes as CFDictionary))
    }

    func delete(account: String) throws {
        try remove(account, dataProtection: true)
        try remove(account, dataProtection: false)
    }

    private func hasAccount(_ account: String, dataProtection: Bool) -> Bool {
        var query = KeychainQuery.base(service: service, account: account, dataProtection: dataProtection)
        query[kSecReturnAttributes as String] = true
        KeychainQuery.silence(&query)
        var result: CFTypeRef?
        return SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess
    }

    private func copy(
        account: String,
        dataProtection: Bool,
        allowingInteraction: Bool
    ) throws -> KeychainStore.Item {
        var query = KeychainQuery.base(service: service, account: account, dataProtection: dataProtection)
        query[kSecReturnData as String] = true
        query[kSecReturnAttributes as String] = true
        if !allowingInteraction { KeychainQuery.silence(&query) }
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        try KeychainStatus.check(status)
        guard let dict = result as? [String: Any] else { throw VaultError.invalidData }
        return try KeychainStore.item(from: dict)
    }

    private func insert(
        account: String, label: String, valueData: Data, genericData: Data?, dataProtection: Bool
    ) throws {
        var query = KeychainQuery.base(service: service, account: account, dataProtection: dataProtection)
        query[kSecAttrLabel as String] = label
        query[kSecValueData as String] = valueData
        if dataProtection {
            query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        }
        if let genericData, !genericData.isEmpty {
            query[kSecAttrGeneric as String] = genericData
        }
        try KeychainStatus.check(SecItemAdd(query as CFDictionary, nil))
    }

    private func remove(_ account: String, dataProtection: Bool) throws {
        let query = KeychainQuery.base(service: service, account: account, dataProtection: dataProtection)
        let status = SecItemDelete(query as CFDictionary)
        if status == errSecItemNotFound { return }
        try KeychainStatus.check(status)
    }
}
