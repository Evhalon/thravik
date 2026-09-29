import Foundation
import RedentKit

/// Serializes a credential into `kSecValueData`.
///
/// macOS file-based Keychain truncates `kSecAttrGeneric` to 64 bytes, which
/// is smaller than the metadata JSON — every imported login used to vanish
/// from the vault and from autofill even though `SecItemAdd` succeeded.
enum KeychainCredentialCodec {
    private struct Payload: Codable {
        var version: Int
        var password: String
        var metadata: CredentialMetadata
    }

    static func encode(_ credential: Credential) throws -> Data {
        let payload = Payload(
            version: 1,
            password: credential.password,
            metadata: CredentialMetadata(credential: credential)
        )
        guard let data = try? JSONEncoder().encode(payload) else { throw VaultError.invalidData }
        return data
    }

    static func decode(_ item: KeychainStore.Item) -> Credential? {
        guard let id = UUID(uuidString: item.account) else { return nil }
        if let payload = try? JSONDecoder().decode(Payload.self, from: item.valueData),
           payload.version == 1
        {
            return payload.metadata.credential(id: id, password: payload.password)
        }
        return legacy(item, id: id)
    }

    private static func legacy(_ item: KeychainStore.Item, id: UUID) -> Credential? {
        guard let generic = item.genericData,
              let metadata = try? JSONDecoder().decode(CredentialMetadata.self, from: generic),
              let password = String(data: item.valueData, encoding: .utf8)
        else { return nil }
        return metadata.credential(id: id, password: password)
    }
}
