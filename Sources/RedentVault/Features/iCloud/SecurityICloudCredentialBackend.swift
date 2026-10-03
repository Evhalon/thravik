import Foundation
import Security
import RedentKit

struct SecurityICloudCredentialBackend: ICloudCredentialBackend {
    private let configuration: ICloudCredentialConfiguration

    init(configuration: ICloudCredentialConfiguration) { self.configuration = configuration }

    func records() async throws -> [ICloudCredentialRecord] {
        var query = Self.baseQuery(configuration)
        query[kSecMatchLimit as String] = kSecMatchLimitAll
        query[kSecReturnAttributes as String] = true
        query[kSecReturnData as String] = true
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return [] }
        try KeychainStatus.check(status)
        guard let items = result as? [[String: Any]] else { throw VaultError.invalidData }
        return try items.map(record)
    }

    func upsert(_ record: ICloudCredentialRecord) async throws {
        let attributes: [String: Any] = [
            kSecValueData as String: record.password,
            kSecAttrGeneric as String: record.metadata
        ]
        let status = SecItemUpdate(Self.itemQuery(configuration, account: record.account) as CFDictionary,
                                   attributes as CFDictionary)
        if status == errSecItemNotFound {
            var query = Self.itemQuery(configuration, account: record.account)
            query[kSecValueData as String] = record.password
            query[kSecAttrGeneric as String] = record.metadata
            query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
            try KeychainStatus.check(SecItemAdd(query as CFDictionary, nil))
            return
        }
        try KeychainStatus.check(status)
    }

    func updateMetadata(_ metadata: Data, account: String) async throws {
        let query = Self.itemQuery(configuration, account: account)
        let attributes: [String: Any] = [kSecAttrGeneric as String: metadata]
        try KeychainStatus.check(SecItemUpdate(query as CFDictionary, attributes as CFDictionary))
    }

    func delete(account: String) async throws {
        try KeychainStatus.check(SecItemDelete(Self.itemQuery(configuration, account: account) as CFDictionary))
    }

    static func baseQuery(_ configuration: ICloudCredentialConfiguration) -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: configuration.service,
         kSecAttrAccessGroup as String: configuration.accessGroup,
         kSecUseDataProtectionKeychain as String: true,
         kSecAttrSynchronizable as String: true]
    }

    static func itemQuery(_ configuration: ICloudCredentialConfiguration, account: String) -> [String: Any] {
        var query = baseQuery(configuration)
        query[kSecAttrAccount as String] = account
        return query
    }

    private func record(_ item: [String: Any]) throws -> ICloudCredentialRecord {
        guard let account = item[kSecAttrAccount as String] as? String,
              let password = item[kSecValueData as String] as? Data,
              let metadata = item[kSecAttrGeneric as String] as? Data else {
            throw VaultError.invalidData
        }
        return ICloudCredentialRecord(account: account, password: password, metadata: metadata)
    }
}
