import Foundation
import RedentKit

/// Serializes a TOTP account into `kSecValueData`. Same reason as
/// `KeychainCredentialCodec`: `kSecAttrGeneric` cannot hold the metadata JSON.
enum KeychainTOTPCodec {
    private struct Payload: Codable {
        var version: Int
        var secret: Data
        var metadata: TOTPMetadata
    }

    static func encode(_ account: TOTPAccount) throws -> Data {
        let payload = Payload(version: 1, secret: account.secret, metadata: TOTPMetadata(account: account))
        guard let data = try? JSONEncoder().encode(payload) else { throw VaultError.invalidData }
        return data
    }

    static func decode(_ item: KeychainStore.Item) -> TOTPAccount? {
        guard let id = UUID(uuidString: item.account) else { return nil }
        if let payload = try? JSONDecoder().decode(Payload.self, from: item.valueData),
           payload.version == 1
        {
            return payload.metadata.account(id: id, secret: payload.secret)
        }
        return legacy(item, id: id)
    }

    private static func legacy(_ item: KeychainStore.Item, id: UUID) -> TOTPAccount? {
        guard let generic = item.genericData,
              let metadata = try? JSONDecoder().decode(TOTPMetadata.self, from: generic)
        else { return nil }
        return metadata.account(id: id, secret: item.valueData)
    }
}
