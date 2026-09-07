import Foundation
import Security
import RedentKit

/// Normalizes `SecItemCopyMatching` results. A single match is a dictionary,
/// not an array; `kSecAttrGeneric` comes back as `Data` *or* a UTF-8 string
/// when the payload is printable JSON. Either mismatch used to drop the
/// whole vault on the floor.
enum KeychainAttributeCodec {
    static func dictionaries(from result: Any?) throws -> [[String: Any]] {
        if let array = result as? [[String: Any]] { return array }
        if let dict = result as? [String: Any] { return [dict] }
        if let array = result as? [Any] {
            let rows = array.compactMap { $0 as? [String: Any] }
            if !rows.isEmpty { return rows }
        }
        throw VaultError.invalidData
    }

    static func account(from attributes: [String: Any]) -> String? {
        let raw = attributes[kSecAttrAccount as String]
        if let string = raw as? String { return string }
        if let data = raw as? Data { return String(data: data, encoding: .utf8) }
        return nil
    }

    static func genericData(from attributes: [String: Any]) -> Data? {
        let raw = attributes[kSecAttrGeneric as String]
        if let data = raw as? Data { return data }
        if let string = raw as? String { return Data(string.utf8) }
        return nil
    }

    static func valueData(from attributes: [String: Any]) -> Data? {
        let raw = attributes[kSecValueData as String]
        if let data = raw as? Data { return data }
        if let string = raw as? String { return Data(string.utf8) }
        return nil
    }
}
